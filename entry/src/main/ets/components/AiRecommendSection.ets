import { RecommendationItemModel } from '../model/PrepModel';
import { AppColors, AppSize } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';

@Component
export struct AiRecommendSection {
  @Link recommendations: RecommendationItemModel[];

  onTap(item: RecommendationItemModel) {
    ToastUtil.show(item.suggestion || '即将跳转');
  }

  build() {
    Column() {
      Row() {
        Text('AI为你推荐')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY);
      }
      .width('100%')
      .margin({ bottom: AppSize.PADDING_MD })

      if (this.recommendations.length === 0) {
        Column() {
          Text('暂无推荐')
            .fontSize(14)
            .fontColor(AppColors.TEXT_HINT)
        }
        .width('100%')
        .padding(AppSize.PADDING_LG)
        .borderRadius(AppSize.RADIUS_LG)
        .backgroundColor(AppColors.CARD)
        .border({ width: 1, color: '#0000000A' })
      } else {
        Column({ space: AppSize.PADDING_MD }) {
          Row() {
            Text('基于你的学习记录推荐')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_SECONDARY);
          }
          .width('100%')
          .margin({ bottom: -4 });

          ForEach(this.recommendations, (item: RecommendationItemModel) => {
            Row() {
              Text(item.emoji)
                .fontSize(20)
                .margin({ right: AppSize.PADDING_MD });

              Column() {
                Text(item.description)
                  .fontSize(14)
                  .fontWeight(FontWeight.Regular)
                  .fontColor(AppColors.TEXT_PRIMARY)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis });
                Text(item.suggestion)
                  .fontSize(12)
                  .fontColor(AppColors.TEXT_SECONDARY)
                  .margin({ top: AppSize.PADDING_SM });
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start);

              Text('›')
                .fontSize(20)
                .fontColor(AppColors.PRIMARY)
                .margin({ left: AppSize.PADDING_SM });
            }
            .width('100%')
            .padding(AppSize.PADDING_MD)
            .borderRadius(AppSize.RADIUS_MD)
            .backgroundColor(AppColors.BG)
            .onClick(() => this.onTap(item));
          }, (item: RecommendationItemModel) => `rec-${item.id}`);
        }
        .width('100%')
        .padding(AppSize.PADDING_MD)
        .borderRadius(AppSize.RADIUS_LG)
        .backgroundColor(AppColors.CARD)
        .border({ width: 1, color: '#0000000A' })
      }
    }
    .width('100%');
  }
}
