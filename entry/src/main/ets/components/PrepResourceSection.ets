import { PrepResourceItemModel } from '../model/PrepModel';
import { AppColors, AppSize } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { prepRepository } from '../repository/PrepRepository';
import { documentRepository } from '../repository/DocumentRepository';
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
  @Link isResourcesLoading: boolean;
  onCategoryChange: (category: string) => void = () => {};
  onLoadMore: () => void = () => {};
  onMoreClick: () => void = () => {};

  private cloneItem(src: PrepResourceItemModel): PrepResourceItemModel {
    return new PrepResourceItemModel(
      src.id,
      src.title,
      src.category,
      src.typeTag,
      src.isHot,
      src.author,
      src.createdAt,
      src.viewCount,
      src.isFavorited,
      src.fileUrl
    );
  }

  private replaceItemAndRefresh(list: PrepResourceItemModel[], index: number): PrepResourceItemModel[] {
    const result: PrepResourceItemModel[] = list.slice();
    result[index] = this.cloneItem(list[index]);
    return result;
  }

  private async toggleFavorite(item: PrepResourceItemModel): Promise<void> {
    const prev = item.isFavorited;
    const next = !prev;
    // 乐观更新：立即修改并通过替换数组元素触发UI刷新
    const idx = this.resources.findIndex((r: PrepResourceItemModel) => r.id === item.id);
    if (idx >= 0) {
      this.resources[idx].isFavorited = next;
      this.resources = this.replaceItemAndRefresh(this.resources, idx);
    }
    const res = await prepRepository.toggleFavorite(item.id, next);
    if (res.success && res.data !== undefined) {
      const finalState: boolean = res.data!;
      // 如果服务端状态和乐观更新不一致，再修正最终状态
      if (finalState !== next) {
        const finalIdx = this.resources.findIndex((r: PrepResourceItemModel) => r.id === item.id);
        if (finalIdx >= 0) {
          this.resources[finalIdx].isFavorited = finalState;
          this.resources = this.replaceItemAndRefresh(this.resources, finalIdx);
        }
      }
      // 收藏/取消收藏后，同步文档库：收藏→创建文档；取消收藏→删除文档
      if (finalState) {
        this.syncToDocumentLibrary(item.id);
      } else {
        this.removeFromDocumentLibrary(item.id);
      }
    } else {
      // 失败回滚
      const rollbackIdx = this.resources.findIndex((r: PrepResourceItemModel) => r.id === item.id);
      if (rollbackIdx >= 0) {
        this.resources[rollbackIdx].isFavorited = prev;
        this.resources = this.replaceItemAndRefresh(this.resources, rollbackIdx);
      }
      ToastUtil.show(res.message || '操作失败，请重试');
    }
  }

  private async syncToDocumentLibrary(resourceId: number): Promise<void> {
    try {
      const syncRes = await documentRepository.createFromResource(resourceId);
      if (syncRes.success && syncRes.data) {
        if (syncRes.data.alreadyExists) {
          Logger.info(TAG, `资源${resourceId}已存在于文档库，跳过同步`);
        } else {
          Logger.info(TAG, `资源${resourceId}已同步到个人文档库`);
        }
      } else {
        Logger.warn(TAG, `资源${resourceId}同步文档库失败：${syncRes.message}`);
      }
    } catch (e) {
      Logger.error(TAG, `资源${resourceId}同步文档库异常`, e as Error);
    }
  }

  private async removeFromDocumentLibrary(resourceId: number): Promise<void> {
    try {
      const delRes = await documentRepository.deleteFromResource(resourceId);
      if (delRes.success) {
        Logger.info(TAG, `资源${resourceId}对应文档已从个人文档库删除`);
      } else {
        Logger.warn(TAG, `资源${resourceId}文档库删除失败：${delRes.message}`);
      }
    } catch (e) {
      Logger.error(TAG, `资源${resourceId}文档库删除异常`, e as Error);
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

      if (this.isResourcesLoading) {
        Column({ space: AppSize.PADDING_SM }) {
          ForEach([1, 2, 3], (_: number) => {
            Row({ space: AppSize.PADDING_MD }) {
              Column()
                .width(44)
                .height(44)
                .borderRadius(AppSize.RADIUS_SM)
                .backgroundColor(AppColors.BG);
              Column({ space: 8 }) {
                Row()
                  .width(60)
                  .height(16)
                  .borderRadius(4)
                  .backgroundColor(AppColors.BG);
                Row()
                  .width('80%')
                  .height(16)
                  .borderRadius(4)
                  .backgroundColor(AppColors.BG);
                Row()
                  .width(120)
                  .height(12)
                  .borderRadius(4)
                  .backgroundColor(AppColors.BG);
              }
              .layoutWeight(1);
            }
            .width('100%')
            .padding(AppSize.PADDING_MD)
            .backgroundColor(AppColors.CARD)
            .borderRadius(AppSize.RADIUS_MD)
            .border({ width: 1, color: '#0000000A' });
          }, (i: number) => `skeleton-${i}`);
        }
        .width('100%');
      } else if (this.resources.length === 0 && this.pageState === 'CONTENT') {
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
