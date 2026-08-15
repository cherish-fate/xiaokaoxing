import {
  NoteListItem,
  NoteListResponse,
  NoteDetailResponse
} from '../api/ApiService';

@Observed
export class NoteItemModel {
  id: number;
  title: string;
  contentPreview: string;
  tags: string[];
  isPinned: boolean;
  sourceType: string;
  updatedAt: string;

  constructor(
    id: number = 0,
    title: string = '',
    contentPreview: string = '',
    tags: string[] = [],
    isPinned: boolean = false,
    sourceType: string = '',
    updatedAt: string = ''
  ) {
    this.id = id;
    this.title = title;
    this.contentPreview = contentPreview;
    this.tags = tags;
    this.isPinned = isPinned;
    this.sourceType = sourceType;
    this.updatedAt = updatedAt;
  }

  static fromApi(src: NoteListItem): NoteItemModel {
    return new NoteItemModel(
      src.id || 0,
      src.title || '',
      src.content_preview || '',
      src.tags || [],
      !!src.is_pinned,
      src.source_type || '',
      src.updated_at || ''
    );
  }

  updatedAtDisplay(): string {
    if (!this.updatedAt) return '';
    try {
      const date: Date = new Date(this.updatedAt);
      const month: number = date.getMonth() + 1;
      const day: number = date.getDate();
      return `${month}月${day}日`;
    } catch (e) {
      return this.updatedAt;
    }
  }

  isOfflineDraft(): boolean {
    return this.sourceType === 'offline';
  }

  tagColor(index: number): string {
    const colors: string[] = ['#7330D1', '#4A7FFF', '#38CFC9', '#F28C3A', '#F54141'];
    return colors[index % colors.length];
  }

  tagBgColor(index: number): string {
    const colors: string[] = ['#F5F0FF', '#E8F0FF', '#E6F7F5', '#FFF5E6', '#FFF0F0'];
    return colors[index % colors.length];
  }
}

@Observed
export class NoteListModel {
  total: number;
  list: NoteItemModel[];

  constructor(total: number = 0, list: NoteItemModel[] = []) {
    this.total = total;
    this.list = list;
  }

  static empty(): NoteListModel {
    return new NoteListModel(0, []);
  }

  static fromList(list: NoteItemModel[], total: number = -1): NoteListModel {
    const t: number = total >= 0 ? total : list.length;
    return new NoteListModel(t, list);
  }

  static fromApi(src: NoteListResponse): NoteListModel {
    const items: NoteItemModel[] = (src.list || []).map(n => NoteItemModel.fromApi(n));
    return new NoteListModel(src.total || 0, items);
  }
}

@Observed
export class NoteDetailModel {
  id: number;
  title: string;
  content: string;
  tags: string[];
  isPinned: boolean;
  sourceType: string;
  sourceId: number | null;
  createdAt: string;
  updatedAt: string;

  constructor(
    id: number = 0,
    title: string = '',
    content: string = '',
    tags: string[] = [],
    isPinned: boolean = false,
    sourceType: string = '',
    sourceId: number | null = null,
    createdAt: string = '',
    updatedAt: string = ''
  ) {
    this.id = id;
    this.title = title;
    this.content = content;
    this.tags = tags;
    this.isPinned = isPinned;
    this.sourceType = sourceType;
    this.sourceId = sourceId;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }

  static empty(): NoteDetailModel {
    return new NoteDetailModel();
  }

  static fromApi(src: NoteDetailResponse): NoteDetailModel {
    return new NoteDetailModel(
      src.id || 0,
      src.title || '',
      src.content || '',
      src.tags || [],
      !!src.is_pinned,
      src.source_type || '',
      src.source_id ?? null,
      src.created_at || '',
      src.updated_at || ''
    );
  }

  updateTitle(title: string): void {
    this.title = title;
  }

  updateContent(content: string): void {
    this.content = content;
  }

  updateTags(tags: string[]): void {
    this.tags = tags;
  }

  addTag(tag: string): void {
    if (tag && !this.tags.includes(tag) && this.tags.length < 3) {
      this.tags = [...this.tags, tag];
    }
  }

  removeTag(tag: string): void {
    this.tags = this.tags.filter(t => t !== tag);
  }
}
