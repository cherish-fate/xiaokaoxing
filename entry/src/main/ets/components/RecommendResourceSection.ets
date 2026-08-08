import { ResourceModel } from '../model/ResourceModel';
import { AppColors, AppSize } from '../utils/Constants';
import { RouteUrls } from '../utils/RouteUrls';
import { RouterUtil } from '../utils/RouterUtil';

@Component
export struct RecommendResourceSection {
  @Prop resources: ResourceModel[] = [];

  build() {
    Column({ space: 12 }) {
      this.Header();
      if (this.resources.length === 0) {
        this.EmptyHint();
      } else {
        Scroll() {
          Row({ space: 12 }) {
            ForEach(this.resources, (item: ResourceModel) => {
              this.ResourceCard(item)
            }, (item: ResourceModel) => `${item.id}`)
          }
          .padding({ left: 20, right: 20 })
        }
        .scrollBar(BarState.Off)
        .scrollable(ScrollDirection.Horizontal)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
  }

  @Builder
  Header() {
    Row() {
      Image($r('app.media.home_material'))
        .width(25)
        .fillColor('#ff6fccc8')
        .margin({right:10})
      Text('本校速推资源')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
      Blank()
      Row({ space: 4 }) {
        Text('更多')
          .fontSize(14)
          .fontColor(AppColors.PRIMARY)
        Text('›')
          .fontSize(14)
          .fontColor(AppColors.PRIMARY)
      }
      .onClick(() => {
        RouterUtil.push(RouteUrls.RESOURCE_LIST);
      })
    }
    .width('100%')
    .padding({ left: 20, right: 20 })
  }

  @Builder
  EmptyHint() {
    Row() {
      Text('暂无推荐资源')
        .fontSize(14)
        .fontColor(AppColors.TEXT_HINT)
    }
    .width('100%')
    .padding(20)
    .justifyContent(FlexAlign.Center)
    .margin({ left: 20, right: 20 })
    .backgroundColor(AppColors.CARD)
    .borderRadius(AppSize.RADIUS_MD)
  }

  @Builder
  ResourceCard(item: ResourceModel) {
    Column({ space: 8 }) {
      Text(item.typeTag)
        .fontSize(11)
        .fontColor(item.tagTextColor())
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .backgroundColor(item.tagColor())
        .borderRadius(8)

      Text(item.title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Row({ space: 4 }) {
        Image($r('app.media.home_look'))
          .width(20)
          .fillColor('#ffd3d3d3')
        Text('点击查看')
          .fontSize(12)
          .fontColor(AppColors.TEXT_HINT)
        Blank()
        Text('›')
          .fontSize(14)
          .fontColor(AppColors.TEXT_HINT)
      }
      .width('100%')
    }
    .width(180)
    .padding(14)
    .backgroundColor(AppColors.CARD)
    .borderRadius(AppSize.RADIUS_MD)
    .shadow({ radius: 6, color: 'rgba(0,0,0,0.04)', offsetY: 2 })
    .onClick(() => {
      RouterUtil.pushWithParams(RouteUrls.RESOURCE_DETAIL, { "resource": item });
    })
  }
}
