import { AppColors } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { RouterUtil } from '../utils/RouterUtil';
import { LoadingView, ErrorView, EmptyView } from '../components/StateViews';
import { BookmarkItemModel, BookmarkListModel } from '../model/BookmarkModel';
import { bookmarkRepository } from '../repository/BookmarkRepository';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct BookmarkListPage {
  @State pageState: string = 'LOADING';
  @State errorMsg: string = '';
  @State model: BookmarkListModel = BookmarkListModel.empty();
  @State selectedColor: string = 'all';
  @State keyword: string = '';

  private searchTimeout: number | null = null;
  private isDeleting: boolean = false;

  async aboutToAppear(): Promise<void> {
    await this.loadData();
  }

  private async loadData(): Promise<void> {
    this.pageState = 'LOADING';
    const colorParam: string | null = this.selectedColor === 'all' ? null : this.selectedColor;
    const keywordParam: string | null = this.keyword.length > 0 ? this.keyword : null;
    const res = await bookmarkRepository.loadBookmarks(colorParam, keywordParam);
    if (res.code === 401) {
      this.pageState = 'ERROR';
      this.errorMsg = res.message || '登录已过期';
      setTimeout(() => RouterUtil.toLogin(), 800);
      return;
    }
    if (!res.success || !res.data) {
      this.pageState = 'ERROR';
      this.errorMsg = res.message || '加载失败';
      return;
    }
    this.model = res.data;
    this.pageState = 'CONTENT';
  }

  private async onRetry(): Promise<void> {
    await this.loadData();
  }

  private onBack(): void {
    RouterUtil.back();
  }

  private onMoreTap(): void {
    ToastUtil.show('更多操作即将上线');
  }

  private onKeywordChange(val: string): void {
    this.keyword = val;
    if (this.searchTimeout !== null) {
      clearTimeout(this.searchTimeout);
    }
    this.searchTimeout = setTimeout(() => {
      this.loadData();
    }, 600) as number;
  }

  private onColorTap(color: string): void {
    if (this.selectedColor === color) return;
    this.selectedColor = color;
    this.loadData();
  }

  // 外层大圆底色（柔和浅色背景）
  private getColorOuterBg(color: string): string {
    switch (color) {
      case 'red':
        return '#FFEAEA';
      case 'yellow':
        return '#FFF3CF';
      case 'green':
        return '#DEF7EE';
      case 'blue':
        return '#E5EDFF';
      case 'purple':
        return '#F0E9FF';
      default:
        return '#F5F7FA';
    }
  }

  // 内层小圆实色
  private getColorInnerColor(color: string): string {
    switch (color) {
      case 'red':
        return '#FFC9C9';
      case 'yellow':
        return '#FFE39A';
      case 'green':
        return '#B2EBD8';
      case 'blue':
        return '#B8CAFF';
      case 'purple':
        return '#D7C9FF';
      default:
        return '#CCCCCC';
    }
  }

  private onItemTap(item: BookmarkItemModel): void {
    if (item.sourceType === 'resource' && item.sourceId > 0) {
      ToastUtil.show('跳转到资源详情');
    } else if (item.sourceType === 'note' && item.sourceId > 0) {
      ToastUtil.show('跳转到笔记详情');
    } else if (item.sourceType === 'question' && item.sourceId > 0) {
      ToastUtil.show('跳转到题目详情');
    } else {
      ToastUtil.show('来源详情即将上线');
    }
  }

  private async onLongPress(item: BookmarkItemModel): Promise<void> {
    if (this.isDeleting) return;
    const confirmed: boolean = await this.showConfirm(
      `确定删除这个书签吗？`
    );
    if (!confirmed) return;
    this.isDeleting = true;
    ToastUtil.show('删除中...');
    try {
      const res = await bookmarkRepository.deleteBookmark(item.id);
      if (res.code === 401) {
        this.pageState = 'ERROR';
        this.errorMsg = res.message || '登录已过期';
        setTimeout(() => RouterUtil.toLogin(), 800);
        return;
      }
      if (!res.success) {
        ToastUtil.show(res.message || '删除失败');
        return;
      }
      ToastUtil.show('删除成功');
      const newList: BookmarkItemModel[] = this.model.list.filter(b => b.id !== item.id);
      const newTotal: number = Math.max(0, this.model.total - 1);
      this.model = BookmarkListModel.fromTotalAndList(newTotal, newList);
    } catch (e) {
      ToastUtil.show('删除失败，请稍后重试');
    } finally {
      this.isDeleting = false;
    }
  }

  private showConfirm(msg: string): Promise<boolean> {
    return new Promise((resolve: (v: boolean) => void) => {
      promptAction.showDialog({
        message: msg,
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '删除', color: '#F54141' }
        ]
      }).then((result: promptAction.ShowDialogSuccessResponse) => {
        resolve(result.index === 1);
      }).catch(() => {
        resolve(false);
      });
    });
  }

  // ========== Build ==========
  build() {
    Column() {
      this.Header()

      if (this.pageState === 'LOADING') {
        LoadingView({ message: '加载中…' })
          .width('100%')
          .layoutWeight(1)
      } else if (this.pageState === 'ERROR') {
        ErrorView({ message: this.errorMsg, onRetry: () => this.onRetry() })
          .width('100%')
          .layoutWeight(1)
      } else {
        Column() {
          this.SearchBar()
          this.ColorFilterBar()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12 })

        if (this.model.list.length === 0) {
          Column() {
            EmptyView({
              icon: '📑',
              message: '还没有书签',
              actionText: ''
            })
          }
          .width('100%')
          .layoutWeight(1)
        } else {
          this.BookmarkList()
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFBF5')
  }

  // ========== Bookmark List ==========
  @Builder
  BookmarkList() {
    List({ space: 16 }) {
      ForEach(this.model.list, (item: BookmarkItemModel) => {
        ListItem() {
          this.BookmarkCard(item)
        }
      }, (item: BookmarkItemModel) => `${item.id}_${item.color}`)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 16, right: 16, top: 4, bottom: 24 })
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  // ========== Header ==========
  @Builder
  Header() {
    Row() {
      Row() {
        Text('‹')
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
      }
      .width(40)
      .height(40)
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)
      .onClick(() => this.onBack())

      Text('精选书签')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Row() {
        Text('⋮')
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .width(40)
      .height(40)
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)
      .onClick(() => this.onMoreTap())
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 8 })
    .backgroundColor(Color.Transparent)
  }

  // ========== Search Bar ==========
  @Builder
  SearchBar() {
    Row({ space: 8 }) {
      Text('🔍')
        .fontSize(16)
        .fontColor(AppColors.TEXT_HINT)

      TextInput({ text: this.keyword, placeholder: '搜索书签内容或备注…' })
        .placeholderColor(AppColors.TEXT_HINT)
        .fontSize(14)
        .fontColor(AppColors.TEXT_PRIMARY)
        .backgroundColor(Color.Transparent)
        .layoutWeight(1)
        .onChange((val: string) => this.onKeywordChange(val))
        .border({ width: 0 })
    }
    .width('100%')
    .height(46)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
    .borderRadius(23)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.04)' })
  }

  // ========== Color Filter Bar ==========
  @Builder
  ColorFilterBar() {
    Row() {
      Row({ space: 8 }) {
        this.ColorDotAll()
        this.ColorDotNormal('red')
        this.ColorDotNormal('yellow')
        this.ColorDotNormal('green')
        this.ColorDotNormal('blue')
        this.ColorDotNormal('purple')
      }
      .layoutWeight(1)

      Text(`${this.model.total} 条`)
        .fontSize(12)
        .fontColor(AppColors.TEXT_HINT)
    }
    .width('100%')
    .margin({ top: 16, bottom: 12 })
  }

  @Builder
  ColorDotAll() {
    Column({ space: 4 }) {
      Column() {
        Text('全部')
          .fontSize(12)
          .fontWeight(this.selectedColor === 'all' ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.selectedColor === 'all' ? AppColors.TEXT_PRIMARY : AppColors.TEXT_SECONDARY)
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor(Color.White)
      .justifyContent(FlexAlign.Center)

      Column() {}
      .width(8)
      .height(8)
      .borderRadius(4)
      .backgroundColor(this.selectedColor === 'all' ? '#C08A2F' : Color.Transparent)
    }
    .alignItems(HorizontalAlign.Center)
    .onClick(() => this.onColorTap('all'))
  }

  @Builder
  ColorDotNormal(color: string) {
    Column({ space: 4 }) {
      Column() {
        Column() {}
        .width(24)
        .height(24)
        .borderRadius(12)
        .backgroundColor(this.getColorInnerColor(color))
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor(this.selectedColor === color ? Color.White : this.getColorOuterBg(color))
      .border({
        width: this.selectedColor === color ? 2 : 0,
        color: this.selectedColor === color ? this.getColorInnerColor(color) : 'transparent'
      })
      .justifyContent(FlexAlign.Center)

      Column() {}
      .width(8)
      .height(8)
      .borderRadius(4)
      .backgroundColor(Color.Transparent)
    }
    .alignItems(HorizontalAlign.Center)
    .onClick(() => this.onColorTap(color))
  }

  // ========== Bookmark Card ==========
  @Builder
  BookmarkCard(item: BookmarkItemModel) {
    Row() {
      Column() {}
      .width(5)
      .height('100%')
      .borderRadius({ topLeft: 16, bottomLeft: 16 })
      .backgroundColor(item.colorBar())

      Column({ space: 10 }) {
        Row() {
          Text('❝')
            .fontSize(20)
            .fontColor('#CCCCCC')
            .fontWeight(FontWeight.Bold)
            .margin({ right: 6 })

          Text(item.quote)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .lineHeight(20)
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(VerticalAlign.Top)

        if (item.note.length > 0) {
          Row({ space: 6 }) {
            Text('💡')
              .fontSize(13)
            Text(item.note)
              .fontSize(12)
              .fontColor(AppColors.TEXT_PRIMARY)
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(item.noteBgColor())
          .borderRadius(8)
        }

        Row() {
          Row({ space: 6 }) {
            Text(item.sourceIcon())
              .fontSize(14)
            Text(item.sourceTitle)
              .fontSize(12)
              .fontColor(AppColors.TEXT_SECONDARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)

          Text(item.dateDisplay())
            .fontSize(12)
            .fontColor(AppColors.TEXT_HINT)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .layoutWeight(1)
      .height('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    }
    .width('100%')
    .height(150)
    .borderRadius(16)
    .backgroundColor(Color.White)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.05)' })
    .onClick(() => this.onItemTap(item))
    .gesture(
      LongPressGesture({ repeat: false, duration: 500 })
        .onAction(() => {
          this.onLongPress(item);
        })
    )
  }
}
