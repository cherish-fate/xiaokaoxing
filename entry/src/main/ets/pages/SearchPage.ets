import { router } from '@kit.ArkUI';
import { AppColors, AppSize } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { Logger } from '../utils/Logger';
import { PrepResourceItemModel } from '../model/PrepModel';
import { searchRepository } from '../repository/SearchRepository';
import { prepRepository } from '../repository/PrepRepository';
import { RouterUtil } from '../utils/RouterUtil';

const TAG = 'SearchPage';
const PAGE_SIZE: number = 10;

@Entry
@Component
struct SearchPage {
  @State keyword: string = '';
  @State searchHistory: string[] = [];
  @State results: PrepResourceItemModel[] = [];
  @State resultsTotal: number = 0;
  @State searchKeyword: string = '';
  @State pageState: string = 'INIT';
  @State loading: boolean = false;
  @State loadMoreState: number = 0;
  @State errorMsg: string = '';
  private offSet: number = 0;
  private debounceTimer: number = -1;

  async aboutToAppear(): Promise<void> {
    this.searchHistory = await searchRepository.getSearchHistory();
  }

  async onInputChanged(): Promise<void> {
    if (this.debounceTimer > 0) clearTimeout(this.debounceTimer);
    if (!this.keyword.trim()) {
      this.pageState = 'INIT';
      this.results = [];
      this.resultsTotal = 0;
      return;
    }
    this.debounceTimer = setTimeout(() => {
      this.doSearch(true);
    }, 500) as number;
  }

  private async doSearch(reset: boolean): Promise<void> {
    const kw = this.keyword.trim();
    if (!kw) return;
    if (reset) {
      this.loading = true;
      this.pageState = 'LOADING';
      this.offSet = 0;
    } else if (this.loadMoreState !== 0) {
      return;
    } else {
      this.loadMoreState = 1;
    }
    const res = await searchRepository.search(kw, PAGE_SIZE, reset ? 0 : this.offSet);
    this.loading = false;
    if (res.code === 401) {
      this.pageState = 'ERROR';
      this.errorMsg = res.message || '登录已过期';
      setTimeout(() => RouterUtil.toLogin(), 800);
      return;
    }
    if (!res.success || !res.data) {
      if (reset) {
        this.pageState = 'ERROR';
        this.errorMsg = res.message || '搜索失败';
      } else {
        ToastUtil.show(res.message || '加载失败');
        this.loadMoreState = 2;
      }
      return;
    }
    if (reset) {
      this.searchKeyword = res.data.keyword || kw;
      this.results = res.data.list;
      await searchRepository.addSearchHistory(kw);
      this.searchHistory = await searchRepository.getSearchHistory();
    } else {
      this.results = this.results.concat(res.data.list);
    }
    this.resultsTotal = res.data.total;
    this.offSet = this.results.length;
    this.pageState = this.results.length === 0 ? 'EMPTY' : 'CONTENT';
    this.loadMoreState = this.results.length >= this.resultsTotal ? 2 : 0;
  }

  onConfirm() {
    if (!this.keyword.trim()) return;
    this.doSearch(true);
  }

  onTapHistory(kw: string) {
    this.keyword = kw;
    this.doSearch(true);
  }

  async onClearHistory() {
    await searchRepository.clearSearchHistory();
    this.searchHistory = [];
  }

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

  async onLoadMore() {
    if (this.loadMoreState !== 0 || this.pageState !== 'CONTENT') return;
    if (this.results.length >= this.resultsTotal) {
      this.loadMoreState = 2;
      return;
    }
    this.loadMoreState = 1;
    await this.doSearch(false);
    if (this.loadMoreState === 1) this.loadMoreState = 0;
  }

  @Builder
  TopBar() {
    Row({ space: AppSize.PADDING_SM }) {
     Image($r('app.media.examDetail_back'))
        .width(40)
        .height(40)
        .padding(10)
        .backgroundColor(AppColors.CARD)
        .borderRadius(20)
        .onClick(() => RouterUtil.back());

      Row() {
        Image($r('app.media.prep_search'))
          .width(20)
        TextInput({ placeholder: '搜索科目、资料、真题...', text: this.keyword })
          .layoutWeight(1)
          .fontSize(14)
          .backgroundColor(Color.Transparent)
          .focusOnTouch(true)
          .onChange((v: string) => {
            this.keyword = v;
            this.onInputChanged();
          })
          .onSubmit(() => this.onConfirm());
      }
      .layoutWeight(1)
      .height(38)
      .padding({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD })
      .backgroundColor(AppColors.BG)
      .borderRadius(999)
      .border({ width: 1, color: '#0000000A' });

      Text('搜索')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.PRIMARY)
        .padding({ left: 4, right: 4 })
        .onClick(() => this.onConfirm());
    }
    .width('100%')
    .padding({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD, top: 12, bottom: 12 })
    .backgroundColor(AppColors.CARD);
  }

  @Builder
  InitView() {
    Column({ space: AppSize.PADDING_LG }) {
      if (this.searchHistory.length > 0) {
        Row() {
          Text('搜索历史')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
            .layoutWeight(1);
          Text('清空')
            .fontSize(12)
            .fontColor(AppColors.TEXT_HINT)
            .onClick(() => this.onClearHistory());
        }
        .width('100%');

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
          ForEach(this.searchHistory, (kw: string, idx: number) => {
            Text(kw)
              .fontSize(12)
              .fontColor(AppColors.TEXT_SECONDARY)
              .padding({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD, top: 8, bottom: 8 })
              .backgroundColor(AppColors.CARD)
              .borderRadius(999)
              .margin({ right: AppSize.PADDING_SM, bottom: AppSize.PADDING_SM })
              .onClick(() => this.onTapHistory(kw));
          }, (kw: string, idx: number) => `h-${idx}`);
        }
        .width('100%');
      }
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  EmptyView() {
    Column() {
      Image($r('app.media.prep_search'))
        .width(20)
      Text(`未找到与「${this.searchKeyword}」相关的资源`)
        .fontSize(14)
        .fontColor(AppColors.TEXT_HINT);
    }
    .width('100%')
    .margin({ top: AppSize.PADDING_LG * 3 })
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  ErrorView() {
    Column() {
      Text('⚠️').fontSize(40).margin({ bottom: AppSize.PADDING_MD });
      Text(this.errorMsg || '搜索出错了')
        .fontSize(14)
        .fontColor(AppColors.TEXT_SECONDARY)
        .margin({ bottom: AppSize.PADDING_LG });
      Text('重试')
        .fontSize(14)
        .fontColor(AppColors.CARD)
        .padding({ left: AppSize.PADDING_LG, right: AppSize.PADDING_LG, top: 10, bottom: 10 })
        .backgroundColor(AppColors.PRIMARY)
        .borderRadius(999)
        .onClick(() => this.doSearch(true));
    }
    .width('100%')
    .margin({ top: AppSize.PADDING_LG * 3 })
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  ResourceCard(item: PrepResourceItemModel) {
    Row({ space: AppSize.PADDING_MD }) {
      Column() { Text(item.iconEmoji()).fontSize(18); }
        .width(44).height(44).borderRadius(AppSize.RADIUS_SM)
        .backgroundColor(item.iconBg()).alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)

      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Text(item.category)
            .fontSize(11).fontWeight(FontWeight.Medium)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(AppSize.RADIUS_SM)
            .backgroundColor(item.categoryTagBg())
            .fontColor(item.categoryTagColor());
          if (item.isHot) {
            Text('⭐ 热门')
              .fontSize(11).fontWeight(FontWeight.Medium)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .borderRadius(AppSize.RADIUS_SM)
              .backgroundColor('#FFF3E8').fontColor('#FF7E02');
          }
        }
        Text(item.title)
          .fontSize(15).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis });
        Row() {
          Text(item.author || '未知').fontSize(12).fontColor(AppColors.TEXT_HINT);
          Text('·').fontSize(12).fontColor(AppColors.TEXT_HINT).opacity(0.5)
            .margin({ left: 4, right: 4 });
          Text(item.shortDate()).fontSize(12).fontColor(AppColors.TEXT_HINT);
          Text('·').fontSize(12).fontColor(AppColors.TEXT_HINT).opacity(0.5)
            .margin({ left: 4, right: 4 });
          Image($r('app.media.home_look'))
            .width(20)
            .fillColor('#ffd3d3d3')
        }
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Start)

      Image(item.isFavorited ?$r('app.media.prep_collected'):$r('app.media.prep_collect'))
        .width(20)
        .onClick(() => this.toggleFavorite(item));
    }
    .width('100%')
    .padding(AppSize.PADDING_MD)
    .backgroundColor(AppColors.CARD)
    .borderRadius(AppSize.RADIUS_MD)
    .border({ width: 1, color: '#0000000A' })
    .onClick(() => {
      RouterUtil.pushToResourceDetail(item.id, JSON.stringify({
        id: item.id, title: item.title, typeTag: item.typeTag, fileUrl: item.fileUrl
      }));
    });
  }

  build() {
    Column() {
      this.TopBar();

      if (this.pageState === 'INIT') {
        Scroll() { this.InitView(); }
          .width('100%').layoutWeight(1).scrollBar(BarState.Off);
      } else if (this.pageState === 'LOADING') {
        Column() { LoadingProgress().width(32).height(32).color(AppColors.PRIMARY); }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center);
      } else if (this.pageState === 'EMPTY') {
        Scroll() { this.EmptyView(); }
          .width('100%').layoutWeight(1).scrollBar(BarState.Off);
      } else if (this.pageState === 'ERROR') {
        Scroll() { this.ErrorView(); }
          .width('100%').layoutWeight(1).scrollBar(BarState.Off);
      } else {
        Scroll() {
          Column({ space: AppSize.PADDING_SM }) {
            ForEach(this.results, (item: PrepResourceItemModel) => {
              this.ResourceCard(item);
            }, (item: PrepResourceItemModel) => `sr-${item.id}-${item.isFavorited}`);

            if (this.loadMoreState === 1) {
              Row() {
                LoadingProgress().width(16).height(16).margin({ right: AppSize.PADDING_SM });
                Text('加载中...').fontSize(12).fontColor(AppColors.TEXT_HINT);
              }
              .width('100%').justifyContent(FlexAlign.Center).padding(AppSize.PADDING_MD);
            } else if (this.loadMoreState === 2 && this.results.length > 0 && this.results.length < this.resultsTotal) {
              Text('— 没有更多了 —')
                .width('100%').textAlign(TextAlign.Center)
                .fontSize(12).fontColor(AppColors.TEXT_HINT)
                .padding(AppSize.PADDING_MD);
            }
          }
          .width('100%').padding(AppSize.PADDING_LG);
        }
        .width('100%').layoutWeight(1).scrollBar(BarState.Off)
        .onReachEnd(() => this.onLoadMore());
      }
    }
    .width('100%').height('100%').backgroundColor(AppColors.BG);
  }
}
