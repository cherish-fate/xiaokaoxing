import {
  apiService,
  ApiResponse,
  AiUploadResponse,
  AiChatRequest
} from '../api/ApiService';
import { AiChatMessageModel, AiConversationModel, AiMsgRole } from '../model/AiChatModel';
import { ResultUtil, AsyncResult } from '../utils/ResultUtil';
import { StorageUtil } from '../utils/StorageUtil';
import { Logger } from '../utils/Logger';

const TAG = 'AiChatRepository';
const CONVO_HISTORY_KEY = 'ai_conversation_history';
const MAX_HISTORY = 20;

interface HistoryMessage {
  role: string;
  content: string;
  timestamp: number;
}

interface SavedConversation {
  conversationId: string;
  messages: HistoryMessage[];
}

interface AiFileResult {
  url: string;
  name: string;
  size: number;
}

export class AiChatRepository {
  private sseBusy: boolean = false;

  async uploadFile(buffer: ArrayBuffer, fileName: string): Promise<AsyncResult<AiFileResult>> {
    const res: ApiResponse<AiUploadResponse> = await apiService.uploadAiFile(buffer, fileName);
    if (res.code === 401) {
      return ResultUtil.fail(401, res.message || '登录已过期');
    }
    if (res.code === 400) {
      return ResultUtil.fail(400, res.message || '不支持的文件格式');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail(res.code, res.message || '上传失败');
    }
    const file: AiFileResult = {
      url: res.data.file_url,
      name: res.data.file_name,
      size: res.data.file_size
    };
    return ResultUtil.success(file);
  }

  async sendAndStream(
    message: string,
    conversationId: string,
    attachmentUrl: string,
    aiMsgRef: AiChatMessageModel,
    onUpdate: () => void,
    onComplete: (convId: string) => void,
    onError: (msg: string) => void
  ): Promise<void> {
    if (this.sseBusy) {
      onError('请等待上一条回复完成');
      return;
    }
    this.sseBusy = true;
    const req: AiChatRequest = {
      message: message,
      conversation_id: conversationId || undefined,
      attachment_url: attachmentUrl || undefined
    };
    let errorMsg: string = '';
    try {
      await apiService.chatStream(
        req,
        (chunk: string) => {
          if (aiMsgRef) {
            aiMsgRef.append(chunk);
            onUpdate();
          }
        },
        (convId: string, fullContent: string) => {
          if (aiMsgRef) {
            if (fullContent && fullContent.length > aiMsgRef.content.length) {
              aiMsgRef.content = fullContent;
            }
            aiMsgRef.isStreaming = false;
          }
          this.sseBusy = false;
          onComplete(convId);
        },
        (msg: string) => {
          errorMsg = msg;
          if (aiMsgRef) {
            aiMsgRef.isError = true;
            aiMsgRef.isStreaming = false;
            if (!aiMsgRef.content) {
              aiMsgRef.content = msg;
            }
          }
          this.sseBusy = false;
          onError(msg);
        }
      );
    } catch (e) {
      Logger.error(TAG, 'sendAndStream error', e as Error);
      if (aiMsgRef) {
        aiMsgRef.isError = true;
        aiMsgRef.isStreaming = false;
        aiMsgRef.content = 'AI 服务暂时不可用，请稍后重试';
      }
      this.sseBusy = false;
      onError(errorMsg || 'AI 服务暂时不可用，请稍后重试');
    }
  }

  isBusy(): boolean {
    return this.sseBusy;
  }

  async loadHistoryConv(): Promise<AiConversationModel> {
    const conv: AiConversationModel = new AiConversationModel('');
    const raw: string = await StorageUtil.getString(CONVO_HISTORY_KEY, '');
    if (!raw) return conv;
    try {
      const saved: SavedConversation = JSON.parse(raw) as SavedConversation;
      conv.conversationId = saved.conversationId || '';
      const savedMsgs: HistoryMessage[] = saved.messages || [];
      for (let i = 0; i < savedMsgs.length; i++) {
        const sm: HistoryMessage = savedMsgs[i];
        const role: AiMsgRole = sm.role === 'ai' ? AiMsgRole.AI : AiMsgRole.USER;
        const m: AiChatMessageModel = new AiChatMessageModel(
          sm.timestamp || Date.now(),
          role,
          sm.content,
          sm.timestamp || Date.now(),
          false,
          false
        );
        conv.messages.push(m);
      }
      return conv;
    } catch (e) {
      Logger.warn(TAG, 'loadHistoryConv parse failed');
      return conv;
    }
  }

  async saveHistoryConv(conv: AiConversationModel): Promise<void> {
    const messages: HistoryMessage[] = conv.messages
      .filter(m => !m.isStreaming)
      .map(m => {
        const history: HistoryMessage = {
          role: m.role === AiMsgRole.AI ? 'ai' : 'user',
          content: m.content,
          timestamp: m.timestamp
        };
        return history;
      })
      .slice(-MAX_HISTORY);
    const saved: SavedConversation = {
      conversationId: conv.conversationId || '',
      messages: messages
    };
    await StorageUtil.put(CONVO_HISTORY_KEY, JSON.stringify(saved));
  }

  async clearHistoryConv(): Promise<void> {
    await StorageUtil.remove(CONVO_HISTORY_KEY);
  }
}

export const aiChatRepository: AiChatRepository = new AiChatRepository();
