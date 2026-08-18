import { AppColors, AppSize, TagStyle } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { RouterUtil } from '../utils/RouterUtil';

interface QuickFuncItem {
  icon: string;
  label: string;
  bg: string;
  prompt: string;
}

const QUICK_ITEMS: QuickFuncItem[] = [
  { icon: '📚', label: '资料拆解', bg: TagStyle.BLUE, prompt: '请帮我拆解并梳理这份复习资料的重点' },
  { icon: '📝', label: 'AI模拟卷', bg: TagStyle.ORANGE, prompt: '请帮我出一套期末模拟试卷' },
  { icon: '🔍', label: '智能搜题', bg: TagStyle.GREEN, prompt: '我想搜索一道题目的解析和考点' },
  { icon: '💬', label: 'AI答疑', bg: TagStyle.PURPLE, prompt: '我有一道题目需要你帮我解答' },
  { icon: '🎧', label: '音频听背', bg: TagStyle.RED, prompt: '' },
  { icon: '🎯', label: '薄弱诊断', bg: TagStyle.BLUE, prompt: '请帮我诊断薄弱知识点并给出复习建议' }
];

@Component
export struct QuickFunctionBar {
  onTap(item: QuickFuncItem) {
    if (item.prompt) {
      // 预填提示词到输入框，由用户确认后再发送
      RouterUtil.pushToAiChat(item.prompt, false);
    } else {
      ToastUtil.show(`${item.label}功能即将上线`);
    }
  }

  build() {
    Column() {
      Row() {
        Text('快捷功能')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY);
      }
      .width('100%')
      .margin({ bottom: AppSize.PADDING_MD })

      Scroll() {
        Row({ space: AppSize.PADDING_MD }) {
          ForEach(QUICK_ITEMS, (item: QuickFuncItem, index: number) => {
            Column() {
              Column() {
                Text(item.icon).fontSize(24);
              }
              .width(52)
              .height(52)
              .borderRadius(AppSize.RADIUS_MD)
              .backgroundColor(item.bg)
              .alignItems(HorizontalAlign.Center)
              .justifyContent(FlexAlign.Center)

              Text(item.label)
                .fontSize(12)
                .fontColor(AppColors.TEXT_PRIMARY)
                .margin({ top: AppSize.PADDING_SM })
            }
            .width(64)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => this.onTap(item));
          }, (item: QuickFuncItem, index: number) => `qf-${index}`)
        }
      }
      .scrollBar(BarState.Off)
      .scrollable(ScrollDirection.Horizontal)
      .width('100%');
    }
    .width('100%');
  }
}