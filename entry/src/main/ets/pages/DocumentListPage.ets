import { AppColors } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { RouterUtil } from '../utils/RouterUtil';
import { LoadingView, ErrorView, EmptyView } from '../components/StateViews';
import { DocumentItemModel, DocumentListModel } from '../model/DocumentModel';
import { documentRepository } from '../repository/DocumentRepository';
import { NoteTagCountModel } from '../model/ToolModel';
import { toolRepository } from '../repository/ToolRepository';
import { promptAction } from '@kit.ArkUI';
import { Logger } from '../utils/Logger';

@Entry
@Component
struct DocumentListPage {
  @State pageState: string = 'LOADING';
  @State errorMsg: string = '';
  @State model: DocumentListModel = DocumentListModel.empty();
  @State selectedCategory: string = '全部';
  @State categoryList: NoteTagCountModel[] = [];
  @State totalCount: number = 0;

  private isLoadingMore: boolean = false;
  private isTogglingOfflineMap: Map<number, boolean> = new Map();
  private isDeleting: boolean = false;
  private readonly PAGE_SIZE: number = 10;

  async aboutToAppear(): Promise<void> {
    await this.loadData();
  }

  private async loadData(): Promise<void> {
    this.pageState = 'LOADING';
    const res = await documentRepository.loadDocuments(
      this.selectedCategory === '全部' ? null : this.selectedCategory,
      this.PAGE_SIZE,
      0
    );
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
    await this.loadCategoryCounts();
    this.pageState = 'CONTENT';
  }

  private async loadCategoryCounts(): Promise<void> {
    const homeRes = await toolRepository.loadToolboxHome();
    if (homeRes.success && homeRes.data) {
      this.categoryList = homeRes.data.documents.categories;
      this.totalCount = homeRes.data.documents.total;
    }
  }

  private async onRetry(): Promise<void> {
    await this.loadData();
  }

  private onBack(): void {
    RouterUtil.back();
  }

  private onCategoryTap(category: string): void {
    if (this.selectedCategory === category) return;
    this.selectedCategory = category;
    this.loadData();
  }

  private async onLoadMore(): Promise<void> {
    if (this.isLoadingMore) return;
    if (!this.model.canLoadMore()) return;
    this.isLoadingMore = true;
    try {
      const res = await documentRepository.loadDocuments(
        this.selectedCategory === '全部' ? null : this.selectedCategory,
        this.PAGE_SIZE,
        this.model.list.length
      );
      if (res.success && res.data) {
        this.model = this.model.appendMore(res.data.list, res.data.total);
      }
    } catch (e) {
      Logger.error('DocumentListPage', 'load more failed', e as Error);
    } finally {
      this.isLoadingMore = false;
    }
  }

  private getCategoryCount(category: string): number {
    if (category === '全部') return this.totalCount;
    for (let i: number = 0; i < this.categoryList.length; i++) {
      if (this.categoryList[i].name === category) {
        return this.categoryList[i].count;
      }
    }
    return 0;
  }

  private async onOfflineToggle(item: DocumentItemModel): Promise<void> {
    if (this.isTogglingOfflineMap.has(item.id)) return;
    this.isTogglingOfflineMap.set(item.id, true);

    const newOffline: boolean = !item.isOffline;
    const updatedList: DocumentItemModel[] = this.model.list.map(d => {
      if (d.id === item.id) {
        const updated: DocumentItemModel = new DocumentItemModel(
          d.id, d.name, d.fileUrl, d.fileSize, d.fileType, d.category,
          newOffline, d.lastOpenedAt
        );
        return updated;
      }
      return d;
    });
    this.model = DocumentListModel.fromTotalAndList(this.model.total, updatedList);

    try {
      const res = await documentRepository.updateOffline(item.id, newOffline);
      if (!res.success) {
        const rollbackList: DocumentItemModel[] = this.model.list.map(d => {
          if (d.id === item.id) {
            const rolled: DocumentItemModel = new DocumentItemModel(
              d.id, d.name, d.fileUrl, d.fileSize, d.fileType, d.category,
              !newOffline, d.lastOpenedAt
            );
            return rolled;
          }
          return d;
        });
        this.model = DocumentListModel.fromTotalAndList(this.model.total, rollbackList);
        ToastUtil.show(res.message || '操作失败');
      } else {
        ToastUtil.show(newOffline ? '已设为离线可用' : '已取消离线');
      }
    } catch (e) {
      const rollbackList2: DocumentItemModel[] = this.model.list.map(d => {
        if (d.id === item.id) {
          const rolled2: DocumentItemModel = new DocumentItemModel(
            d.id, d.name, d.fileUrl, d.fileSize, d.fileType, d.category,
            !newOffline, d.lastOpenedAt
          );
          return rolled2;
        }
        return d;
      });
      this.model = DocumentListModel.fromTotalAndList(this.model.total, rollbackList2);
      ToastUtil.show('操作失败，请稍后重试');
    } finally {
      this.isTogglingOfflineMap.delete(item.id);
    }
  }

  private onItemTap(item: DocumentItemModel): void {
    ToastUtil.show('文件预览功能即将上线');
  }

  private async onLongPress(item: DocumentItemModel): Promise<void> {
    if (this.isDeleting) return;
    const confirmed: boolean = await this.showConfirm(
      `确定删除文档"${item.name}"吗？删除后将无法恢复。`
    );
    if (!confirmed) return;
    this.isDeleting = true;
    ToastUtil.show('删除中...');
    try {
      const res = await documentRepository.deleteDocument(item.id);
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
      const newList: DocumentItemModel[] = this.model.list.filter(d => d.id !== item.id);
      const newTotal: number = Math.max(0, this.model.total - 1);
      this.model = DocumentListModel.fromTotalAndList(newTotal, newList);
      this.totalCount = Math.max(0, this.totalCount - 1);
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
        if (this.model.list.length === 0) {
          Column() {
            EmptyView({
              icon: '📁',
              message: '还没有文档',
              actionText: ''
            })
          }
          .width('100%')
          .layoutWeight(1)
        } else {
          this.DocumentListWithScroll()
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG)
  }

  // ========== Scroll + List ==========
  @Builder
  DocumentListWithScroll() {
    List({ space: 12 }) {
      ListItem() {
        Column() {
          this.CategoryTabs()
        }
        .margin({ bottom: 4 })
      }

      ForEach(this.model.list, (item: DocumentItemModel) => {
        ListItem() {
          this.DocumentCard(item)
        }
      }, (item: DocumentItemModel) => `${item.id}_${item.isOffline}`)

      if (this.isLoadingMore) {
        ListItem() {
          Row() {
            Text('加载中...')
              .fontSize(12)
              .fontColor(AppColors.TEXT_HINT)
          }
          .width('100%')
          .padding(16)
          .justifyContent(FlexAlign.Center)
        }
      } else if (this.model.canLoadMore()) {
        ListItem() {
          Column() {
            Blank(20)
          }
          .width('100%')
        }
        .onAppear(() => {
          this.onLoadMore();
        })
      } else if (this.model.list.length >= this.model.total && this.model.list.length > 0) {
        ListItem() {
          Row() {
            Text('— 已加载全部 —')
              .fontSize(12)
              .fontColor(AppColors.TEXT_HINT)
          }
          .width('100%')
          .padding(16)
          .justifyContent(FlexAlign.Center)
        }
      }
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 16, right: 16, top: 12, bottom: 16 })
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  // ========== Header ==========
  @Builder
  Header() {
    Row() {
      Image($r('app.media.examDetail_back'))
        .width(40)
        .height(40)
        .padding(10)
        .backgroundColor(AppColors.CARD)
        .borderRadius(20)
        .onClick(() => this.onBack())

      Text('个人文档库')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 8 })
    .backgroundColor(Color.White)
  }

  // ========== Category Tabs ==========
  @Builder
  CategoryTabs() {
    Scroll() {
      Row({ space: 24 }) {
        this.CategoryTabItem('全部')
        this.CategoryTabItem('真题')
        this.CategoryTabItem('笔记')
        this.CategoryTabItem('收藏')
        this.CategoryTabItem('导出')
      }
      .padding({ right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .padding({ left: 4, right: 4, top: 8, bottom: 8 })
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 8 })
  }

  @Builder
  CategoryTabItem(name: string) {
    Column({ space: 6 }) {
      Row({ space: 4 }) {
        Text(name)
          .fontSize(14)
          .fontWeight(this.selectedCategory === name ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.selectedCategory === name ? '#4A7FFF' : AppColors.TEXT_SECONDARY)
        Text(this.getCategoryCount(name).toString())
          .fontSize(14)
          .fontWeight(this.selectedCategory === name ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.selectedCategory === name ? '#4A7FFF' : AppColors.TEXT_HINT)
      }

      if (this.selectedCategory === name) {
        Column() {}
        .width(20)
        .height(3)
        .borderRadius(2)
        .backgroundColor('#4A7FFF')
      } else {
        Column() {}
        .width(20)
        .height(3)
        .backgroundColor(Color.Transparent)
      }
    }
    .onClick(() => this.onCategoryTap(name))
  }

  // ========== Document Card ==========
  @Builder
  DocumentCard(item: DocumentItemModel) {
    Row({ space: 12 }) {
      this.FileIcon(item)

      Column({ space: 6 }) {
        Text(item.name)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row({ space: 8 }) {
          if (item.isOffline) {
            this.OfflineTag()
          }
          Text(this.buildMetaLine(item))
            .fontSize(12)
            .fontColor(AppColors.TEXT_HINT)
            .maxLines(1)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      this.OfflineCheckbox(item)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.04)' })
    .border({ width: 1, color: 'rgba(0,0,0,0.04)' })
    .onClick(() => this.onItemTap(item))
    .gesture(
      LongPressGesture({ repeat: false, duration: 500 })
        .onAction(() => {
          this.onLongPress(item);
        })
    )
  }

  private buildMetaLine(item: DocumentItemModel): string {
    const date: string = item.dateDisplay();
    const size: string = item.fileSizeDisplay();
    if (date.length > 0) {
      return `${date} · ${size}`;
    }
    return size;
  }

  @Builder
  FileIcon(item: DocumentItemModel) {
    Column() {
      Row() {
        Text(item.fileTypeIcon())
          .fontSize(22)
      }
      .width(48)
      .height(48)
      .borderRadius(12)
      .backgroundColor(item.fileTypeIconBgColor())
      .justifyContent(FlexAlign.Center)
    }
    .width(48)
    .height(48)
  }

  @Builder
  OfflineTag() {
    Text('离线可用')
      .fontSize(11)
      .fontWeight(FontWeight.Medium)
      .fontColor('#38CFC9')
      .padding({ left: 8, right: 8, top: 2, bottom: 2 })
      .backgroundColor('#E6F7F5')
      .borderRadius(6)
  }

  @Builder
  OfflineCheckbox(item: DocumentItemModel) {
    if (item.isOffline) {
      Row() {
        Text('✓')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width(22)
      .height(22)
      .borderRadius(6)
      .backgroundColor('#4A7FFF')
      .justifyContent(FlexAlign.Center)
      .onClick(() => this.onOfflineToggle(item))
    } else {
      Row() {}
      .width(22)
      .height(22)
      .borderRadius(6)
      .border({ width: 1.5, color: '#CCCCCC' })
      .onClick(() => this.onOfflineToggle(item))
    }
  }

}
