import { AppColors, AppSize, TagStyle } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';

interface QuickFuncItem {
  icon: string;
  label: string;
  bg: string;
}

const QUICK_ITEMS: QuickFuncItem[] = [
  { icon: '📚', label: '资料拆解', bg: TagStyle.BLUE },
  { icon: '📝', label: 'AI模拟卷', bg: TagStyle.ORANGE },
  { icon: '🔍', label: '智能搜题', bg: TagStyle.GREEN },
  { icon: '💬', label: 'AI答疑', bg: TagStyle.PURPLE },
  { icon: '🎧', label: '音频听背', bg: TagStyle.RED },
  { icon: '🎯', label: '薄弱诊断', bg: TagStyle.BLUE }
];

@Component
export struct QuickFunctionBar {
  onTap(label: string) {
    ToastUtil.show(`${label}功能即将上线`);
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
            .onClick(() => this.onTap(item.label));
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
