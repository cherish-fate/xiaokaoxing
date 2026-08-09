import { PrepResourceItemModel } from '../model/PrepModel';
import { AppColors, AppSize } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { prepRepository } from '../repository/PrepRepository';
import { RouterUtil } from '../utils/RouterUtil';
import { Logger } from '../utils/Logger';

const TAG = 'PrepResourceSection';
const CATEGORIES: string[] = ['真题试卷', '复习提纲', '课件考点', '自测题库'];

@Component
export struct PrepResourceSection {
  @Link currentCategory: string;
  @Link resources: PrepResourceItemModel[];
  @Link resourcesTotal: number;
  @Link loadMoreState: number;
  @Link pageState: string;
  onCategoryChange: (category: string) => void = () => {};
  onLoadMore: () => void = () => {};
  onMoreClick: () => void = () => {};

  private async toggleFavorite(item: PrepResourceItemModel): Promise<void> {
    const prev = item.isFavorited;
    item.isFavorited = !item.isFavorited;
    const res = await prepRepository.toggleFavorite(item.id, item.isFavorited);
    if (res.success && res.data !== undefined) {
      item.isFavorited = res.data!;
      ToastUtil.show(res.data ? '收藏成功' : '已取消收藏');
    } else {
      item.isFavorited = prev;
      ToastUtil.show(res.message || '操作失败，请重试');
    }
  }

  onCardTap(item: PrepResourceItemModel) {
    RouterUtil.pushToResourceDetail(item.id, JSON.stringify({
      id: item.id,
      title: item.title,
      typeTag: item.typeTag,
      fileUrl: item.fileUrl
    }));
  }

  @Builder
  CategoryTabs() {
    Row({ space: AppSize.PADDING_SM }) {
      ForEach(CATEGORIES, (cat: string) => {
        Text(cat)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentCategory === cat ? AppColors.CARD : AppColors.TEXT_SECONDARY)
          .padding({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD, top: 6, bottom: 6 })
          .borderRadius(999)
          .backgroundColor(this.currentCategory === cat ? AppColors.PRIMARY : AppColors.CARD)
          .border({ width: 1, color: this.currentCategory === cat ? AppColors.PRIMARY : '#0000000A' })
          .onClick(() => this.onCategoryChange(cat));
      }, (cat: string) => `tab-${cat}`);
    }
    .width('100%')
  }

  @Builder
  ResourceCard(item: PrepResourceItemModel) {
    Row({ space: AppSize.PADDING_MD }) {
      Column() {
        Text(item.iconEmoji()).fontSize(18);
      }
      .width(44)
      .height(44)
      .borderRadius(AppSize.RADIUS_SM)
      .backgroundColor(item.iconBg())
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)

      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Text(item.category)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(AppSize.RADIUS_SM)
            .backgroundColor(item.categoryTagBg())
            .fontColor(item.categoryTagColor());
          if (item.isHot) {
            Text('⭐ 热门')
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .borderRadius(AppSize.RADIUS_SM)
              .backgroundColor('#FFF3E8')
              .fontColor('#FF7E02');
          }
        }
        .width('100%');

        Text(item.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });

        Row() {
          Text(item.author || '未知')
            .fontSize(12).fontColor(AppColors.TEXT_HINT);
          Text('·').fontSize(12).fontColor(AppColors.TEXT_HINT).opacity(0.5)
            .margin({ left: 4, right: 4 });
          Text(item.shortDate())
            .fontSize(12).fontColor(AppColors.TEXT_HINT);
          Text('·').fontSize(12).fontColor(AppColors.TEXT_HINT).opacity(0.5)
            .margin({ left: 4, right: 4 });
          Image($r('app.media.home_look'))
            .width(20)
            .fillColor('#ffd3d3d3')
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column() {
        Image(item.isFavorited ?$r('app.media.prep_collected'):$r('app.media.prep_collect'))
          .width(20)
      }
      .width(32)
      .height(32)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .borderRadius(999)
      .onClick(() => this.toggleFavorite(item));
    }
    .width('100%')
    .padding(AppSize.PADDING_MD)
    .backgroundColor(AppColors.CARD)
    .borderRadius(AppSize.RADIUS_MD)
    .border({ width: 1, color: '#0000000A' })
    .onClick(() => this.onCardTap(item));
  }

  build() {
    Column({ space: AppSize.PADDING_MD }) {
      Row() {
        Row() {
          Text('本校专业资源库')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY);
        }
        .layoutWeight(1);
        Text('更多 ›')
          .fontSize(12)
          .fontColor(AppColors.PRIMARY)
          .onClick(() => this.onMoreClick());
      }
      .width('100%');

      this.CategoryTabs();

      if (this.resources.length === 0 && this.pageState === 'CONTENT') {
        Column() {
          Text('📭').fontSize(32).margin({ bottom: AppSize.PADDING_SM });
          Text('暂无资源')
            .fontSize(14)
            .fontColor(AppColors.TEXT_HINT);
        }
        .width('100%')
        .padding(AppSize.PADDING_LG * 2);
      } else {
        Column({ space: AppSize.PADDING_SM }) {
          ForEach(this.resources, (item: PrepResourceItemModel) => {
            this.ResourceCard(item);
          }, (item: PrepResourceItemModel) => `res-${item.id}-${item.isFavorited}`);
        }
        .width('100%');
      }

      if (this.loadMoreState === 1) {
        Row() {
          LoadingProgress().width(16).height(16).margin({ right: AppSize.PADDING_SM });
          Text('加载中...').fontSize(12).fontColor(AppColors.TEXT_HINT);
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding(AppSize.PADDING_MD);
      } else if (this.loadMoreState === 2 && this.resources.length > 0 && this.resources.length < this.resourcesTotal) {
        Text('— 没有更多了 —')
          .width('100%')
          .textAlign(TextAlign.Center)
          .fontSize(12)
          .fontColor(AppColors.TEXT_HINT)
          .padding(AppSize.PADDING_MD);
      }
    }
    .width('100%');
  }
}
