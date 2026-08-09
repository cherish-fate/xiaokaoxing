import { router } from '@kit.ArkUI';
import { AppColors, AppSize } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { Logger } from '../utils/Logger';
import { AiConversationModel, AiChatMessageModel, AiMsgRole } from '../model/AiChatModel';
import { aiChatRepository } from '../repository/AiChatRepository';
import { RouterUtil } from '../utils/RouterUtil';

const TAG = 'AiChatPage';

@Entry
@Component
struct AiChatPage {
  @State conversation: AiConversationModel = new AiConversationModel();
  @State inputText: string = '';
  @State sending: boolean = false;
  @State uploading: boolean = false;
  @State attachmentUrl: string = '';
  @State attachmentName: string = '';
  @State scrollLastKey: number = 0;
  @State uiTick: number = 0;

  private scroller: Scroller = new Scroller();
  private autoSendMsg: string = '';
  private shouldAutoSend: boolean = false;

  aboutToAppear(): void {
    try {
      const params = router.getParams() as Record<string, Object>;
      if (params) {
        if (typeof params['initialMessage'] === 'string') {
          this.autoSendMsg = params['initialMessage'] || '';
        }
        if (params['autoSend'] === '1') {
          this.shouldAutoSend = true;
        }
      }
    } catch (e) {
      Logger.warn(TAG, 'getParams failed');
    }
    this.restoreHistory();
  }

  async onPageShow(): Promise<void> {
    await this.restoreHistory();
    if (this.shouldAutoSend && this.autoSendMsg) {
      this.inputText = this.autoSendMsg;
      this.shouldAutoSend = false;
      setTimeout(() => this.sendMessage(), 200);
    } else if (this.autoSendMsg && this.conversation.messages.length === 0) {
      this.inputText = this.autoSendMsg;
      this.autoSendMsg = '';
    }
  }

  async aboutToDisappear(): Promise<void> {
    await aiChatRepository.saveHistoryConv(this.conversation);
  }

  async restoreHistory(): Promise<void> {
    if (this.conversation.messages.length > 0) return;
    const saved = await aiChatRepository.loadHistoryConv();
    this.conversation = saved;
    this.scrollLastKey = Date.now();
  }

  forceUiRefresh() {
    this.uiTick = Date.now();
    setTimeout(() => {
      try { this.scroller.scrollEdge(Edge.Bottom); } catch (e) {}
    }, 20);
  }

  async sendMessage(): Promise<void> {
    const msg = this.inputText.trim();
    if (!msg) return;
    if (this.sending || aiChatRepository.isBusy()) {
      ToastUtil.show('请等待上一条回复完成');
      return;
    }
    this.sending = true;
    this.conversation.addUserMsg(msg, this.attachmentUrl, this.attachmentName);
    this.inputText = '';
    const attUrl = this.attachmentUrl;
    const attName = this.attachmentName;
    this.attachmentUrl = '';
    this.attachmentName = '';
    this.forceUiRefresh();
    const aiMsg = this.conversation.addAiStreaming();
    await aiChatRepository.sendAndStream(
      msg,
      this.conversation.conversationId,
      attUrl,
      aiMsg,
      ():void => this.forceUiRefresh(),
      (convId: string) => {
        if (convId) this.conversation.conversationId = convId;
        this.sending = false;
        aiChatRepository.saveHistoryConv(this.conversation);
        this.forceUiRefresh();
      },
      (errMsg: string) => {
        this.sending = false;
        ToastUtil.show(errMsg || 'AI 服务错误');
        this.forceUiRefresh();
      }
    );
  }

  onTapUpload() {
    ToastUtil.show('请在系统相册中选择文件（PDF/DOC/DOCX/TXT）');
    this.attachmentName = '示例附件.pdf';
    this.attachmentUrl = 'https://example.com/demo.pdf';
    ToastUtil.show('已附加文件：示例附件.pdf');
  }

  onClearAttachment() {
    this.attachmentUrl = '';
    this.attachmentName = '';
  }

  async onClearChat() {
    await aiChatRepository.clearHistoryConv();
    this.conversation = new AiConversationModel();
    ToastUtil.show('对话已清空');
  }

  onRetry() {
    const lastUser = this.conversation.lastUserMsg();
    const lastAi = this.conversation.lastAiMsg();
    if (!lastUser) return;
    if (lastAi && lastAi.isError) {
      const idx = this.conversation.messages.indexOf(lastAi);
      if (idx >= 0) this.conversation.messages.splice(idx, 1);
    }
    this.inputText = lastUser.content;
    this.sendMessage();
  }

  @Builder
  TopBar() {
    Row() {
      Image($r('app.media.examDetail_back'))
        .width(40)
        .height(40)
        .padding(10)
        .backgroundColor(AppColors.CARD)
        .borderRadius(20)
        .onClick(() => RouterUtil.back());

      Column() {
        Text('AI学习助手')
          .fontSize(16).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY);
        Text('校考AI，帮你高效备考')
          .fontSize(11).fontColor(AppColors.TEXT_SECONDARY);
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Center);

      Text('清空')
        .fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
        .padding({ left: AppSize.PADDING_SM, right: AppSize.PADDING_SM })
        .onClick(() => this.onClearChat());
    }
    .width('100%')
    .padding({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD, top: 12, bottom: 12 })
    .backgroundColor(AppColors.CARD)
    .border({ width: { bottom: 1 }, color: '#0000000A' });
  }

  @Builder
  MessageBubble(msg: AiChatMessageModel) {
    if (msg.role === AiMsgRole.USER) {
      Row() {
        Blank();
        Column() {
          Text(msg.content)
            .fontSize(14)
            .fontColor(AppColors.CARD)
            .padding(AppSize.PADDING_MD);
        }
        .constraintSize({ maxWidth: '70%' })
        .backgroundColor(AppColors.PRIMARY)
        .borderRadius({ topLeft: 16, topRight: 16, bottomLeft: 16, bottomRight: 4 });
      }
      .width('100%')
      .padding({ top: AppSize.PADDING_SM, bottom: AppSize.PADDING_SM });
    } else {
      Row() {
        Column() {
          Image($r('app.media.prep_Ai'))
            .width(40)
            .borderRadius(20)
        }
        .width(32).height(32).borderRadius(999)
        .backgroundColor('#E8F0FF')
        .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
        .margin({ right: AppSize.PADDING_SM });

        Column({ space: AppSize.PADDING_SM }) {
          Column() {
            Text(msg.content || (msg.isStreaming ? '正在思考中...' : ''))
              .fontSize(14).fontColor(AppColors.TEXT_PRIMARY)
              .padding(AppSize.PADDING_MD);
            if (msg.isStreaming && !msg.content) {
              Row({ space: 4 }) {
                Text('●').fontSize(8).fontColor(AppColors.PRIMARY);
                Text('●').fontSize(8).fontColor(AppColors.PRIMARY).margin({ left: 2 });
                Text('●').fontSize(8).fontColor(AppColors.PRIMARY).margin({ left: 2 });
              }
              .margin({ left: AppSize.PADDING_MD, bottom: AppSize.PADDING_SM });
            }
          }
          .constraintSize({ maxWidth: '80%' })
          .backgroundColor(AppColors.CARD)
          .border({ width: 1, color: '#0000000A' })
          .borderRadius({ topLeft: 16, topRight: 16, bottomLeft: 4, bottomRight: 16 });

          if (msg.isError) {
            Text('重新发送')
              .fontSize(12).fontColor(AppColors.PRIMARY)
              .padding({ left: AppSize.PADDING_SM, right: AppSize.PADDING_SM, top: 4, bottom: 4 })
              .borderRadius(999).backgroundColor('#E8F0FF')
              .onClick(() => this.onRetry());
          }
        }
        .alignItems(HorizontalAlign.Start);

        Blank();
      }
      .width('100%')
      .padding({ top: AppSize.PADDING_SM, bottom: AppSize.PADDING_SM });
    }
  }

  @Builder
  EmptyHint() {
    Column({ space: AppSize.PADDING_LG }) {
      Column() {
        Image($r('app.media.prep_Ai'))
          .width(40)
          .borderRadius(20)
      }

      Text('你好！我是校考星AI学习助手')
        .fontSize(16).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY);
      Text('我可以帮你生成模拟卷、拆解资料、诊断薄弱点')
        .fontSize(13).fontColor(AppColors.TEXT_SECONDARY);
    }
    .width('100%')
    .margin({ top: AppSize.PADDING_LG * 3 })
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  AttachmentBar() {
    Row() {
      Image($r('app.media.aichat_file')) .width(20)
      Text(this.attachmentName).fontSize(12).fontColor(AppColors.TEXT_PRIMARY)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1);
      Text('✕').fontSize(14).fontColor(AppColors.TEXT_HINT).width(24).height(24)
        .textAlign(TextAlign.Center).onClick(() => this.onClearAttachment());
    }
    .width('100%')
    .padding({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD, top: 8, bottom: 8 })
    .backgroundColor('#E8F0FF')
    .borderRadius(AppSize.RADIUS_MD)
    .margin({ left: AppSize.PADDING_LG, right: AppSize.PADDING_LG, bottom: AppSize.PADDING_SM });
  }

  @Builder
  InputBar() {
    Column() {
      if (this.attachmentUrl && this.attachmentName) {
        this.AttachmentBar();
      }
      Row({ space: AppSize.PADDING_SM }) {
        Column() {
          Image($r('app.media.aichat_file'))
            .width(20)
        }
        .width(38).height(38).borderRadius(999)
        .backgroundColor(AppColors.CARD)
        .border({ width: 1, color: '#0000000A' })
        .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
        .opacity(this.uploading ? 0.5 : 1.0)
        .onClick(() => {
          if (this.uploading) return;
          this.onTapUpload();
        });

        TextInput({ placeholder: '输入你想说的...', text: this.inputText })
          .layoutWeight(1)
          .height(38)
          .padding({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD })
          .backgroundColor(AppColors.CARD)
          .borderRadius(999)
          .border({ width: 1, color: '#0000000A' })
          .fontSize(14)
          .maxLength(500)
          .onChange((v: string) => { this.inputText = v; })
          .onSubmit(() => this.sendMessage());

        Text('发送')
          .fontSize(14).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.CARD)
          .padding({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD, top: 9, bottom: 9 })
          .borderRadius(999)
          .backgroundColor(this.sending || !this.inputText.trim() ? '#CCCCCC' : AppColors.PRIMARY)
          .onClick(() => this.sendMessage());
      }
      .width('100%')
      .padding({
        left: AppSize.PADDING_LG,
        right: AppSize.PADDING_LG,
        top: AppSize.PADDING_SM,
        bottom: AppSize.PADDING_MD
      });
    }
    .width('100%')
    .backgroundColor(AppColors.CARD)
    .border({ width: { top: 1 }, color: '#0000000A' });
  }

  build() {
    Column() {
      this.TopBar();

      if (this.conversation.messages.length === 0) {
        Scroll() { this.EmptyHint(); }
          .width('100%').layoutWeight(1).scrollBar(BarState.Off);
      } else {
        Scroll(this.scroller) {
          Column({ space: 0 }) {
            ForEach(
              this.conversation.messages,
              (msg: AiChatMessageModel) => {
                this.MessageBubble(msg);
              },
              (msg: AiChatMessageModel, index: number) => `msg-${msg.id}-${index}-${msg.timestamp}-${this.uiTick}-${msg.content.length}`
            );
          }
          .width('100%')
          .padding({
            left: AppSize.PADDING_LG,
            right: AppSize.PADDING_LG,
            top: AppSize.PADDING_MD,
            bottom: AppSize.PADDING_MD
          });
        }
        .width('100%').layoutWeight(1).scrollBar(BarState.Off);
      }

      this.InputBar();
    }
    .width('100%').height('100%').backgroundColor(AppColors.BG);
  }
}
