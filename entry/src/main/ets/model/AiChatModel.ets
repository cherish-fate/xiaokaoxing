export enum AiMsgRole {
  USER = 'user',
  AI = 'ai'
}

@Observed
export class AiChatMessageModel {
  id: number;
  role: AiMsgRole;
  content: string;
  timestamp: number;
  isStreaming: boolean;
  isError: boolean;

  constructor(
    id: number,
    role: AiMsgRole,
    content: string,
    timestamp: number = Date.now(),
    isStreaming: boolean = false,
    isError: boolean = false
  ) {
    this.id = id;
    this.role = role;
    this.content = content;
    this.timestamp = timestamp;
    this.isStreaming = isStreaming;
    this.isError = isError;
  }

  append(chunk: string): void {
    this.content += chunk;
  }
}

@Observed
export class AiConversationModel {
  conversationId: string;
  messages: AiChatMessageModel[];
  attachmentUrl: string;
  attachmentName: string;

  constructor(conversationId: string = '') {
    this.conversationId = conversationId;
    this.messages = [];
    this.attachmentUrl = '';
    this.attachmentName = '';
  }

  addUserMsg(msg: string, attachmentUrl: string = '', attachmentName: string = ''): AiChatMessageModel {
    const id = Date.now() + Math.floor(Math.random() * 1000);
    const m = new AiChatMessageModel(id, AiMsgRole.USER, msg, Date.now(), false, false);
    this.messages.push(m);
    this.attachmentUrl = attachmentUrl;
    this.attachmentName = attachmentName;
    return m;
  }

  addAiStreaming(): AiChatMessageModel {
    const id = Date.now() + Math.floor(Math.random() * 1000);
    const m = new AiChatMessageModel(id, AiMsgRole.AI, '', Date.now(), true, false);
    this.messages.push(m);
    return m;
  }

  lastAiMsg(): AiChatMessageModel | undefined {
    return this.messages.filter(m => m.role === AiMsgRole.AI).slice(-1)[0];
  }

  lastUserMsg(): AiChatMessageModel | undefined {
    return this.messages.filter(m => m.role === AiMsgRole.USER).slice(-1)[0];
  }
}
