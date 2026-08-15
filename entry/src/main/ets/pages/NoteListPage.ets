import { AppColors } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { NoteItemModel, NoteListModel } from '../model/NoteModel';
import { NoteTagCountModel } from '../model/ToolModel';
import { noteRepository } from '../repository/NoteRepository';
import { toolRepository } from '../repository/ToolRepository';
import { LoadingView, ErrorView, EmptyView } from '../components/StateViews';
import { RouterUtil } from '../utils/RouterUtil';
import { RouteUrls } from '../utils/RouteUrls';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct NoteListPage {
  @State pageState: string = 'LOADING';
  @State errorMsg: string = '';
  @State model: NoteListModel = NoteListModel.empty();
  @State tagList: NoteTagCountModel[] = [];
  @State selectedTag: string = '全部';
  @State keyword: string = '';
  @State searchValue: string = '';
  @State showSearch: boolean = false;

  @State showActionMenu: boolean = false;
  @State actionMenuNoteId: number = 0;
  @State actionMenuPosX: number = 0;
  @State actionMenuPosY: number = 0;
  private isDeleting: boolean = false;
  private isTogglingPin: boolean = false;

  aboutToAppear(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    this.pageState = 'LOADING';
    const tagParam: string | null = this.selectedTag === '全部' ? null : this.selectedTag;

    const res = await noteRepository.loadNotes(tagParam, this.keyword || null, 50, 0);
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

    this.loadTagCounts();

    this.pageState = 'CONTENT';
  }

  private async loadTagCounts(): Promise<void> {
    const homeRes = await toolRepository.loadToolboxHome();
    if (homeRes.success && homeRes.data) {
      this.tagList = homeRes.data.notes.tags;
    }
  }

  private async onRetry(): Promise<void> {
    this.pageState = 'LOADING';
    await this.loadData();
  }

  private onTagTap(tag: string): void {
    this.selectedTag = tag;
    this.loadData();
  }

  private onSearchSubmit(): void {
    this.keyword = this.searchValue;
    this.showSearch = false;
    this.loadData();
  }

  private onItemTap(item: NoteItemModel): void {
    if (this.showActionMenu) {
      this.closeActionMenu();
      return;
    }
    const params: Record<string, Object> = {
      'id': String(item.id)
    };
    RouterUtil.pushWithParams(RouteUrls.NOTE_EDITOR, params);
  }

  private onCreateTap(): void {
    const params: Record<string, Object> = {
      'id': '0'
    };
    RouterUtil.pushWithParams(RouteUrls.NOTE_EDITOR, params);
  }

  private onBack(): void {
    RouterUtil.back();
  }

  private onMoreTap(): void {
    ToastUtil.show('更多功能即将上线');
  }

  private onLongPress(item: NoteItemModel, x: number, y: number): void {
    this.actionMenuNoteId = item.id;
    this.actionMenuPosX = x;
    this.actionMenuPosY = y;
    this.showActionMenu = true;
  }

  private closeActionMenu(): void {
    this.showActionMenu = false;
    this.actionMenuNoteId = 0;
  }

  private getSelectedNote(): NoteItemModel | null {
    for (let i: number = 0; i < this.model.list.length; i++) {
      if (this.model.list[i].id === this.actionMenuNoteId) {
        return this.model.list[i];
      }
    }
    return null;
  }

  private async onDeleteAction(): Promise<void> {
    const note: NoteItemModel | null = this.getSelectedNote();
    this.closeActionMenu();
    if (!note) return;
    if (this.isDeleting) return;

    const confirmed: boolean = await this.showConfirm(
      `确定删除笔记"${note.title}"吗？删除后将无法恢复。`
    );
    if (!confirmed) return;

    this.isDeleting = true;
    ToastUtil.show('删除中...');
    try {
      const res = await noteRepository.deleteNote(note.id);
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
      this.model = NoteListModel.fromList(
        this.model.list.filter(n => n.id !== note.id),
        this.model.total - 1
      );
      if (this.model.list.length === 0 && this.selectedTag === '全部') {
        this.tagList = [];
        this.loadTagCounts();
      }
    } catch (e) {
      ToastUtil.show('删除失败，请稍后重试');
    } finally {
      this.isDeleting = false;
    }
  }

  private onEditAction(): void {
    const note: NoteItemModel | null = this.getSelectedNote();
    this.closeActionMenu();
    if (!note) return;
    const params: Record<string, Object> = {
      'id': String(note.id)
    };
    RouterUtil.pushWithParams(RouteUrls.NOTE_EDITOR, params);
  }

  private async onTogglePinAction(): Promise<void> {
    const note: NoteItemModel | null = this.getSelectedNote();
    this.closeActionMenu();
    if (!note) return;
    if (this.isTogglingPin) return;

    this.isTogglingPin = true;
    try {
      const newPinned: boolean = !note.isPinned;
      const res = await noteRepository.togglePin(note.id, newPinned);
      if (!res.success) {
        ToastUtil.show(res.message || '操作失败');
        return;
      }
      const updatedList: NoteItemModel[] = this.model.list.map(n => {
        if (n.id === note.id) {
          const updated: NoteItemModel = NoteItemModel.fromApi({
            id: n.id,
            title: n.title,
            content_preview: n.contentPreview,
            tags: n.tags,
            is_pinned: newPinned,
            source_type: n.sourceType,
            updated_at: n.updatedAt
          });
          return updated;
        }
        return n;
      });
      const sortedList: NoteItemModel[] = updatedList.sort((a, b) => {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return 0;
      });
      this.model = NoteListModel.fromList(sortedList, this.model.total);
      ToastUtil.show(newPinned ? '已置顶' : '已取消置顶');
    } catch (e) {
      ToastUtil.show('操作失败，请稍后重试');
    } finally {
      this.isTogglingPin = false;
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

  build() {
    Stack() {
      Column() {
        this.Header();

        if (this.showSearch) {
          this.SearchBar();
        }

        if (this.pageState === 'LOADING') {
          Column() {
            LoadingView({ message: '加载中…' })
          }
          .width('100%')
          .layoutWeight(1)
        } else if (this.pageState === 'ERROR') {
          Column() {
            ErrorView({ message: this.errorMsg, onRetry: () => this.onRetry() })
          }
          .width('100%')
          .layoutWeight(1)
        } else {
          if (this.model.list.length === 0) {
            Column() {
              EmptyView({
                icon: '📝',
                message: '还没有笔记，点击右下角创建',
                actionText: ''
              })
            }
            .width('100%')
            .layoutWeight(1)
          } else {
            Scroll() {
              Column() {
                this.TagFilters();
                this.NoteList();
                Blank(80)
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 16 })
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Off)
          }
        }

        this.FAB()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BG)

      if (this.showActionMenu) {
        this.ActionMenuOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ActionMenuOverlay() {
    Column() {
      Column() {
        this.ActionMenuList()
      }
      .backgroundColor('rgba(255,255,255,0.9)')
      .borderRadius(16)
      .shadow({ radius: 20, color: 'rgba(0,0,0,0.15)' })
      .backgroundBlurStyle(BlurStyle.Thin)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('rgba(0,0,0,0.25)')
    .onClick(() => this.closeActionMenu())
  }

  @Builder
  ActionMenuList() {
    Column() {
      this.ActionMenuItem(
        '📝 编辑',
        () => this.onEditAction()
      )
      Divider()
        .color('rgba(0,0,0,0.06)')
        .width('100%')
        .height(1)

      this.ActionMenuItem(
        this.getSelectedNote()?.isPinned ? '📌 取消置顶' : '📌 置顶',
        () => this.onTogglePinAction()
      )
      Divider()
        .color('rgba(0,0,0,0.06)')
        .width('100%')
        .height(1)

      this.ActionMenuItem(
        '🗑️ 删除',
        () => this.onDeleteAction()
      )
    }
    .width(160)
  }

  @Builder
  ActionMenuItem(label: string, onTap: () => void) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(AppColors.TEXT_PRIMARY)
    }
    .width('100%')
    .height(48)
    .justifyContent(FlexAlign.Center)
    .onClick(() => onTap())
  }

  @Builder
  Header() {
    Column() {
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

        Text('学习笔记')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row() {
          Text('⋯')
            .fontSize(22)
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
      .height(48)
      .padding({ left: 4, right: 4 })
    }
    .width('100%')
    .padding({ left: 12, right: 12 })
    .backgroundColor(Color.White)
  }

  @Builder
  SearchBar() {
    Row({ space: 8 }) {
      Row({ space: 6 }) {
        Text('🔍')
          .fontSize(14)
        TextInput({ placeholder: '搜索笔记标题或内容...', text: this.searchValue })
          .fontSize(14)
          .fontColor(AppColors.TEXT_PRIMARY)
          .placeholderColor(AppColors.TEXT_HINT)
          .layoutWeight(1)
          .onSubmit(() => this.onSearchSubmit())
          .onChange((val: string) => {
            this.searchValue = val;
          })
        if (this.searchValue.length > 0) {
          Text('✕')
            .fontSize(14)
            .fontColor(AppColors.TEXT_HINT)
            .onClick(() => {
              this.searchValue = '';
              this.keyword = '';
              this.loadData();
            })
        }
      }
      .width('100%')
      .height(40)
      .padding({ left: 12, right: 12 })
      .backgroundColor('#F1F3F7')
      .borderRadius(12)

      if (this.keyword.length > 0) {
        Text('搜索')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#7330D1')
          .onClick(() => this.onSearchSubmit())
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor(Color.White)
  }

  @Builder
  TagFilters() {
    Scroll() {
      Row({ space: 8 }) {
        this.TagFilterItem('全部', this.model.total)
        ForEach(this.tagList, (tag: NoteTagCountModel) => {
          this.TagFilterItem(tag.name, tag.count)
        }, (tag: NoteTagCountModel) => tag.name)
      }
      .padding({ right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  TagFilterItem(name: string, count: number) {
    Row({ space: 4 }) {
      Text(name)
        .fontSize(13)
        .fontWeight(this.selectedTag === name ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.selectedTag === name ? '#7330D1' : AppColors.TEXT_SECONDARY)
      Text(count.toString())
        .fontSize(12)
        .fontWeight(this.selectedTag === name ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.selectedTag === name ? '#7330D1' : AppColors.TEXT_HINT)
    }
    .padding({ left: 14, right: 14, top: 7, bottom: 7 })
    .backgroundColor(this.selectedTag === name ? '#F5F0FF' : Color.White)
    .borderRadius(999)
    .border({
      width: 1,
      color: this.selectedTag === name ? '#7330D1' : 'rgba(0,0,0,0.06)'
    })
    .onClick(() => this.onTagTap(name))
  }

  @Builder
  NoteList() {
    Column({ space: 12 }) {
      ForEach(this.model.list, (item: NoteItemModel) => {
        this.NoteCard(item)
      }, (item: NoteItemModel) => `${item.id}`)
    }
    .width('100%')
  }

  @Builder
  NoteCard(item: NoteItemModel) {
    Column() {
      Row() {
        Column({ space: 6 }) {
          Text(item.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(item.contentPreview)
            .fontSize(13)
            .fontColor(AppColors.TEXT_SECONDARY)
            .lineHeight(20)
            .width('100%')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        if (item.isPinned) {
          Text('📌')
            .fontSize(16)
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Row() {
        Row({ space: 6 }) {
          ForEach(item.tags, (tag: string, idx: number) => {
            this.TagPill(tag, item.tagColor(idx), item.tagBgColor(idx))
          }, (tag: string) => tag)
        }
        .layoutWeight(1)

        Text(item.updatedAtDisplay())
          .fontSize(11)
          .fontColor(AppColors.TEXT_HINT)

        if (item.isOfflineDraft()) {
          Text('离线草稿')
            .fontSize(10)
            .fontColor('#F28C3A')
            .fontWeight(FontWeight.Medium)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor('#FFF5E6')
            .borderRadius(6)
            .margin({ left: 6 })
        }
      }
      .width('100%')
      .margin({ top: 12 })
      .alignItems(VerticalAlign.Center)
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
        .onAction((e: GestureEvent) => {
          if (e.fingerList.length === 1) {
            this.onLongPress(item, e.offsetX, e.offsetY);
          }
        })
    )
  }

  @Builder
  TagPill(tag: string, textColor: string, bgColor: string) {
    Row({ space: 2 }) {
      Text(tag)
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(textColor)
    }
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    .backgroundColor(bgColor)
    .borderRadius(6)
  }

  @Builder
  FAB() {
    Row() {
      Text('+')
        .fontSize(28)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
    }
    .width(56)
    .height(56)
    .linearGradient({
      direction: GradientDirection.RightBottom,
      colors: [['#9B59D0', 0], ['#7330D1', 1]]
    })
    .borderRadius(28)
    .justifyContent(FlexAlign.Center)
    .shadow({ radius: 20, color: 'rgba(115,48,209,0.35)' })
    .margin({ right: 20, bottom: 24 })
    .alignSelf(ItemAlign.End)
    .onClick(() => this.onCreateTap())
  }
}
