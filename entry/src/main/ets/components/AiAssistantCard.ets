import { AppColors, AppSize, TagStyle } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { RouterUtil } from '../utils/RouterUtil';
import { RouteUrls } from '../utils/RouteUrls';

@Component
export struct AiAssistantCard {
  @Builder
  SuggestionDot() {
    Text('')
      .width(6)
      .height(6)
      .borderRadius(999)
      .backgroundColor('#4A7FFF')
      .opacity(0.5)
      .margin({ right: AppSize.PADDING_SM })
  }

  onPickSuggestion(word: string) {
    RouterUtil.pushToAiChat(word, true);
  }

  onUpload() {
    ToastUtil.show('请在AI对话页中上传资料');
    RouterUtil.pushToAiChat('', false);
  }

  onGenerate() {
    RouterUtil.pushToAiChat('', true);
  }

  build() {
    Column() {
      Row() {
        Column() {
          Image($r('app.media.prep_Ai'))
            .width(40)
            .height(40)
            .borderRadius(20)
        }

        Column() {
          Text('AI学习助手')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A3A8A');
          Text('校考AI，帮你高效备考')
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .margin({ bottom: AppSize.PADDING_MD })

      Column() {
        Text('输入你想学的，或试试：')
          .fontSize(14)
          .fontColor(AppColors.TEXT_HINT)
          .margin({ bottom: AppSize.PADDING_SM });

        Column({ space: 4 }) {
          Row() {
            this.SuggestionDot();
            Text('出一套高数期末模拟卷')
              .fontSize(12)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .width('100%')
          .onClick(() => this.onPickSuggestion('出一套高数期末模拟卷'));

          Row() {
            this.SuggestionDot();
            Text('拆解这份复习提纲')
              .fontSize(12)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .width('100%')
          .onClick(() => this.onPickSuggestion('拆解这份复习提纲'));

          Row() {
            this.SuggestionDot();
            Text('诊断我高数薄弱点')
              .fontSize(12)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .width('100%')
          .onClick(() => this.onPickSuggestion('诊断我高数薄弱点'));
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .backgroundColor(AppColors.CARD)
      .borderRadius(AppSize.RADIUS_MD)
      .border({ width: 1, color: '#0000000A' })
      .padding(AppSize.PADDING_MD);

      Row({ space: AppSize.PADDING_MD }) {
        Row() {
          Text('上传资料').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.PRIMARY);
        }
        .layoutWeight(1)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .borderRadius(999)
        .backgroundColor(AppColors.CARD)
        .border({ width: 1, color: '#DBEAFE' })
        .onClick(() => this.onUpload());

        Row() {
          Text('立即生成').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.CARD);
        }
        .layoutWeight(1)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .borderRadius(999)
        .backgroundColor(AppColors.PRIMARY)
        .shadow({
          radius: 12,
          color: 'rgba(74,127,255,0.3)',
          offsetX: 0,
          offsetY: 4
        })
        .onClick(() => this.onGenerate());
      }
      .width('100%')
      .margin({ top: AppSize.PADDING_MD })
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .borderRadius(AppSize.RADIUS_LG)
    .linearGradient({
      direction: GradientDirection.RightBottom,
      colors: [['#E8F0FF', 0.0], ['#F0F6FF', 0.6], ['#FFFFFF', 1.0]]
    })
    .border({ width: 1, color: 'rgba(74,127,255,0.12)' })
  }
}
