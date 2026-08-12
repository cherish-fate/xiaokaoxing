import { AppColors, AppSize } from '../utils/Constants';
import { CommunityResourceModel } from '../model/CommunityHomeModel';
import { RouterUtil } from '../utils/RouterUtil';
import { RouteUrls } from '../utils/RouteUrls';

@Component
export struct CommunityResourceCard {
  @Link latestResources: CommunityResourceModel[];

  @Builder
  ResourceItem(res: CommunityResourceModel) {
    Row({ space: 12 }) {
      Column() {
        Text('📄')
          .fontSize(22)
      }
      .width(44)
      .height(44)
      .backgroundColor('#F2F5FA')
      .borderRadius(10)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column({ space: 6 }) {
        Text(res.title)
          .fontSize(14)
          .fontColor(AppColors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Row({ space: 8 }) {
          Text(res.author)
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
          Text(res.createdAt)
            .fontSize(12)
            .fontColor(AppColors.TEXT_HINT)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column() {
        if (res.status === '已上线' || res.status === '已审核') {
          Row({ space: 3 }) {
            Text('✓')
              .fontSize(11)
              .fontColor(Color.White)
            Text('已审核')
              .fontSize(11)
              .fontColor(Color.White)
          }
          .backgroundColor(AppColors.SUCCESS)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(8)
        } else {
          Row({ space: 3 }) {
            Image($r('app.media.community_shalou'))
              .width(20)
            Text('审核中')
              .fontSize(11)
              .fontColor(AppColors.WARNING)
          }
          .backgroundColor('#FFF3E8')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(8)
        }
      }
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
  }

  build() {
    Column() {
      Row() {
        Row({ space: 4 }) {
          Text('📁')
            .fontSize(18)
          Text('本校最新共享资料')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .layoutWeight(1)

        Row({ space: 2 }) {
          Text('更多')
            .fontSize(13)
            .fontColor(AppColors.PRIMARY)
          Text('>')
            .fontSize(13)
            .fontColor(AppColors.PRIMARY)
        }
        .onClick(() => RouterUtil.push(RouteUrls.COMMUNITY_UPLOAD))
      }
      .width('100%')
      .margin({ bottom: 8 })

      Column() {
        if (this.latestResources.length === 0) {
          Column({ space: 6 }) {
            Text('暂无资料')
              .fontSize(14)
              .fontColor(AppColors.TEXT_HINT)
            Text('成为第一个分享资料的同学吧')
              .fontSize(12)
              .fontColor(AppColors.TEXT_HINT)
          }
          .width('100%')
          .padding({ top: 24, bottom: 24 })
        } else {
          ForEach(this.latestResources, (res: CommunityResourceModel, index: number) => {
            Column() {
              if (index > 0) {
                Divider()
                  .color(AppColors.DIVIDER)
                  .strokeWidth(1)
              }
              this.ResourceItem(res)
            }
            .width('100%')
          })
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }
}
