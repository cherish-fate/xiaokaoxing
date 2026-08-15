import { BookmarkItem } from '../api/ApiService';
import { DateUtil } from '../utils/DateUtil';

@Observed
export class BookmarkItemModel {
  id: number;
  quote: string;
  sourceTitle: string;
  sourceUrl: string;
  sourceType: string;
  sourceId: number;
  note: string;
  color: string;
  createdAt: string;

  constructor(
    id: number = 0,
    quote: string = '',
    sourceTitle: string = '',
    sourceUrl: string = '',
    sourceType: string = '',
    sourceId: number = 0,
    note: string = '',
    color: string = 'yellow',
    createdAt: string = ''
  ) {
    this.id = id;
    this.quote = quote;
    this.sourceTitle = sourceTitle;
    this.sourceUrl = sourceUrl;
    this.sourceType = sourceType;
    this.sourceId = sourceId;
    this.note = note;
    this.color = color;
    this.createdAt = createdAt;
  }

  static empty(): BookmarkItemModel {
    return new BookmarkItemModel();
  }

  static fromApi(src: BookmarkItem): BookmarkItemModel {
    return new BookmarkItemModel(
      src.id || 0,
      src.quote || '',
      src.source_title || '',
      src.source_url || '',
      src.source_type || '',
      src.source_id || 0,
      src.note || '',
      src.color || 'yellow',
      src.created_at || ''
    );
  }

  colorBar(): string {
    switch (this.color) {
      case 'red':
        return '#FF5C5C';
      case 'yellow':
        return '#FFD24D';
      case 'green':
        return '#5FD9B5';
      case 'blue':
        return '#668CFF';
      case 'purple':
        return '#8C66FF';
      default:
        return '#FFD24D';
    }
  }

  noteBgColor(): string {
    return '#FFF8D6';
  }

  sourceIcon(): string {
    switch (this.sourceType) {
      case 'resource':
        return '📄';
      case 'note':
        return '📝';
      case 'question':
        return '❓';
      default:
        return '📄';
    }
  }

  dateDisplay(): string {
    if (this.createdAt.length === 0) return '';
    const short: string = DateUtil.toShortDate(this.createdAt);
    if (short.length >= 5) {
      const parts: string[] = short.split('-');
      if (parts.length === 3) {
        return `${parts[1]}月${parts[2]}日`;
      }
    }
    return short;
  }
}

@Observed
export class BookmarkListModel {
  total: number;
  list: BookmarkItemModel[];

  constructor(total: number = 0, list: BookmarkItemModel[] = []) {
    this.total = total;
    this.list = list;
  }

  static empty(): BookmarkListModel {
    return new BookmarkListModel();
  }

  static fromTotalAndList(total: number, list: BookmarkItemModel[]): BookmarkListModel {
    return new BookmarkListModel(total, list);
  }
}
