import { AppColors } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { noteRepository } from '../repository/NoteRepository';
import { LoadingView, ErrorView } from '../components/StateViews';
import { RouterUtil } from '../utils/RouterUtil';

@Entry
@Component
struct NoteEditorPage {
  @State pageState: string = 'LOADING';
  @State errorMsg: string = '';
  @State noteId: number = 0;
  @State title: string = '';
  @State content: string = '';
  @State tags: string[] = [];
  @State isNewNote: boolean = false;
  @State isSaving: boolean = false;
  @State lastSavedAt: string = '';
  @State showTagInput: boolean = false;
  @State newTagInput: string = '';
  private saveTimer: number = -1;

  aboutToAppear(): void {
    const params: Record<string, Object> = RouterUtil.getParams();
    const idStr: string = String(params['id'] || '0');
    const id: number = parseInt(idStr) || 0;
    if (id > 0) {
      this.isNewNote = false;
      this.loadDetail(id);
    } else {
      this.isNewNote = true;
      this.noteId = 0;
      this.title = '';
      this.content = '';
      this.tags = [];
      this.pageState = 'CONTENT';
    }
  }

  private async loadDetail(id: number): Promise<void> {
    this.pageState = 'LOADING';
    const res = await noteRepository.loadNoteDetail(id);
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
    this.noteId = res.data.id;
    this.title = res.data.title;
    this.content = res.data.content;
    this.tags = [...res.data.tags];
    this.pageState = 'CONTENT';
  }

  private async onRetry(): Promise<void> {
    if (this.noteId > 0) {
      await this.loadDetail(this.noteId);
    } else {
      this.pageState = 'CONTENT';
    }
  }

  private onTitleChange(title: string): void {
    this.title = title;
    this.scheduleAutoSave();
  }

  private onContentChange(content: string): void {
    this.content = content;
    this.scheduleAutoSave();
  }

  private scheduleAutoSave(): void {
    if (this.saveTimer !== -1) {
      clearTimeout(this.saveTimer);
    }
    this.saveTimer = setTimeout(() => {
      this.autoSave();
    }, 2000) as number;
  }

  private async autoSave(): Promise<void> {
    if (this.isSaving) return;
    this.isSaving = true;
    try {
      if (this.isNewNote) {
        if (this.title.trim() || this.content.trim()) {
          const res = await noteRepository.createNote(
            this.title,
            this.content,
            this.tags
          );
          if (res.success && res.data) {
            this.noteId = res.data.id;
            this.isNewNote = false;
            this.lastSavedAt = '刚刚';
          }
        }
      } else if (this.noteId > 0) {
        const res = await noteRepository.updateNote(
          this.noteId,
          this.title,
          this.content,
          this.tags
        );
        if (res.success) {
          this.lastSavedAt = '刚刚';
        }
      }
    } catch (e) {
      console.error('Auto save failed', e);
    }
    this.isSaving = false;
  }

  private async onSave(): Promise<void> {
    if (this.isSaving) return;
    ToastUtil.show('保存中...');
    await this.autoSave();
    RouterUtil.back();
  }

  private onBack(): void {
    if (this.title.trim() || this.content.trim()) {
      this.autoSave();
    }
    setTimeout(() => RouterUtil.back(), 100);
  }

  private onAddTag(): void {
    if (this.tags.length >= 3) {
      ToastUtil.show('最多添加3个标签');
      return;
    }
    this.showTagInput = true;
  }

  private onConfirmAddTag(tag: string): void {
    const trimmed: string = tag.trim();
    if (trimmed && !this.tags.includes(trimmed) && this.tags.length < 3) {
      this.tags = [...this.tags, trimmed];
      this.scheduleAutoSave();
    }
    this.newTagInput = '';
    this.showTagInput = false;
  }

  private onTagInputChange(val: string): void {
    this.newTagInput = val;
  }

  private onTagInputSubmit(): void {
    this.onConfirmAddTag(this.newTagInput);
  }

  private onTagInputCancel(): void {
    this.newTagInput = '';
    this.showTagInput = false;
  }

  private onRemoveTag(tag: string): void {
    this.tags = this.tags.filter(t => t !== tag);
    this.scheduleAutoSave();
  }

  private onToolbarAction(action: string): void {
    let insertText: string = '';
    switch (action) {
      case 'B':
        insertText = '****';
        break;
      case 'I':
        insertText = '**';
        break;
      case 'U':
        insertText = '<u></u>';
        break;
      case 'H1':
        insertText = '\n# ';
        break;
      case 'H2':
        insertText = '\n## ';
        break;
      case '·':
        insertText = '\n- ';
        break;
      case '1.':
        insertText = '\n1. ';
        break;
      case '"':
        insertText = '\n> ';
        break;
      case '{}':
        insertText = '\n```\n\n```';
        break;
    }
    if (insertText) {
      this.content = this.content + insertText;
      this.scheduleAutoSave();
    }
  }

  build() {
    Column() {
      this.Header();

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
        this.TagBar();
        this.Toolbar();

        Scroll() {
          Column() {
            TextArea({ text: this.content ,placeholder:'开始记录你的想法...'})
              .width('100%')
              .height(400)
              .fontSize(15)
              .fontColor(AppColors.TEXT_PRIMARY)
              .lineHeight(26)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .padding(16)
              .onChange((val: string) => this.onContentChange(val))
              .placeholderColor(AppColors.TEXT_HINT)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }

      this.SaveBar();
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG)
  }

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

      TextInput({ placeholder: '未命名笔记', text: this.title })
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .placeholderColor(AppColors.TEXT_HINT)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow(TextOverflow.Ellipsis)
        .backgroundColor(Color.Transparent)
        .border({ width: 0 })
        .onChange((val: string) => this.onTitleChange(val))

      Row({ space: 4 }) {
        Text('保存')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor('#7330D1')
          .borderRadius(999)
          .onClick(() => this.onSave())
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 8 })
    .backgroundColor(Color.White)
  }

  @Builder
  TagBar() {
    Row({ space: 8 }) {
      ForEach(this.tags, (tag: string) => {
        this.TagItem(tag)
      }, (tag: string) => tag)

      if (this.showTagInput && this.tags.length < 3) {
        Row({ space: 4 }) {
          TextInput({ placeholder: '输入标签', text: this.newTagInput })
            .fontSize(12)
            .fontColor(AppColors.TEXT_PRIMARY)
            .placeholderColor(AppColors.TEXT_HINT)
            .width(80)
            .height(24)
            .padding({ left: 8, right: 8 })
            .backgroundColor(Color.White)
            .borderRadius(6)
            .border({ width: 1, color: '#7330D1' })
            .onChange((val: string) => this.onTagInputChange(val))
            .onSubmit(() => this.onTagInputSubmit())
          Text('✕')
            .fontSize(10)
            .fontColor(AppColors.TEXT_HINT)
            .onClick(() => this.onTagInputCancel())
        }
      } else if (this.tags.length < 3) {
        Row({ space: 4 }) {
          Text('+ 添加标签')
            .fontSize(12)
            .fontColor('#7330D1')
            .fontWeight(FontWeight.Medium)
        }
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .backgroundColor('#F5F0FF')
        .borderRadius(6)
        .onClick(() => this.onAddTag())
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 8 })
    .backgroundColor(Color.White)
  }

  @Builder
  TagItem(tag: string) {
    Row({ space: 4 }) {
      Text(tag)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#7330D1')
      Text('✕')
        .fontSize(10)
        .fontColor('#7330D1')
        .onClick(() => this.onRemoveTag(tag))
    }
    .padding({ left: 10, right: 8, top: 6, bottom: 6 })
    .backgroundColor('#F5F0FF')
    .borderRadius(6)
  }

  @Builder
  Toolbar() {
    Row({ space: 2 }) {
      this.ToolbarBtn('B', true)
      this.ToolbarBtn('I', false)
      this.ToolbarBtn('U', false)
      this.ToolbarDivider()
      this.ToolbarBtn('H1', false)
      this.ToolbarBtn('H2', false)
      this.ToolbarDivider()
      this.ToolbarBtn('·', false)
      this.ToolbarBtn('1.', false)
      this.ToolbarDivider()
      this.ToolbarBtn('"', false)
      this.ToolbarBtn('{}', false)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor(Color.White)
    .margin({ bottom: 4 })
  }

  @Builder
  ToolbarBtn(label: string, isBold: boolean) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontWeight(isBold ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(AppColors.TEXT_SECONDARY)
    }
    .width(32)
    .height(32)
    .borderRadius(8)
    .justifyContent(FlexAlign.Center)
    .onClick(() => this.onToolbarAction(label))
  }

  @Builder
  ToolbarDivider() {
    Column()
      .width(1)
      .height(16)
      .backgroundColor('#E5E7EB')
      .margin({ left: 4, right: 4 })
  }

  @Builder
  SaveBar() {
    Row({ space: 6 }) {
      Text('✓')
        .fontSize(12)
        .fontColor('#38CFC9')
      Text('已自动保存 · ' + (this.lastSavedAt || '刚刚'))
        .fontSize(12)
        .fontColor(AppColors.TEXT_HINT)
    }
    .width('100%')
    .height(36)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(Color.White)
    .border({ width: 1, color: AppColors.DIVIDER })
  }
}
