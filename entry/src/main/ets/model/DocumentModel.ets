import { DocumentItem } from '../api/ApiService';
import { DateUtil } from '../utils/DateUtil';

@Observed
export class DocumentItemModel {
  id: number;
  name: string;
  fileUrl: string;
  fileSize: number;
  fileType: string;
  category: string;
  isOffline: boolean;
  lastOpenedAt: string;

  constructor(
    id: number = 0,
    name: string = '',
    fileUrl: string = '',
    fileSize: number = 0,
    fileType: string = '',
    category: string = '',
    isOffline: boolean = false,
    lastOpenedAt: string = ''
  ) {
    this.id = id;
    this.name = name;
    this.fileUrl = fileUrl;
    this.fileSize = fileSize;
    this.fileType = fileType;
    this.category = category;
    this.isOffline = isOffline;
    this.lastOpenedAt = lastOpenedAt;
  }

  static empty(): DocumentItemModel {
    return new DocumentItemModel();
  }

  static fromApi(src: DocumentItem): DocumentItemModel {
    return new DocumentItemModel(
      src.id || 0,
      src.name || '',
      src.file_url || '',
      src.file_size || 0,
      src.file_type || '',
      src.category || '',
      !!src.is_offline,
      src.last_opened_at || ''
    );
  }

  fileSizeDisplay(): string {
    const bytes: number = this.fileSize;
    if (bytes === 0) return '0 B';
    const k: number = 1024;
    const sizes: string[] = ['B', 'KB', 'MB', 'GB'];
    const i: number = Math.floor(Math.log(bytes) / Math.log(k));
    const safeI: number = Math.min(i, sizes.length - 1);
    return `${(bytes / Math.pow(k, safeI)).toFixed(1)} ${sizes[safeI]}`;
  }

  dateDisplay(): string {
    if (this.lastOpenedAt.length === 0) return '';
    const short: string = DateUtil.toShortDate(this.lastOpenedAt);
    if (short.length >= 5) {
      const parts: string[] = short.split('-');
      if (parts.length === 3) {
        return `${parts[1]}月${parts[2]}日`;
      }
    }
    return short;
  }

  fileTypeIcon(): string {
    const type: string = this.fileType.toLowerCase();
    switch (type) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📘';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'ppt':
      case 'pptx':
        return '📽';
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return '🖼';
      case 'md':
        return '📝';
      case 'txt':
        return '📋';
      default:
        return '📁';
    }
  }

  fileTypeIconBgColor(): string {
    const type: string = this.fileType.toLowerCase();
    switch (type) {
      case 'pdf':
        return '#FFF0F0';
      case 'doc':
      case 'docx':
        return '#E8F0FF';
      case 'xls':
      case 'xlsx':
        return '#E6F7F5';
      case 'ppt':
      case 'pptx':
        return '#FFF3E8';
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return '#E6F7F5';
      case 'md':
        return '#F5F0FF';
      default:
        return '#F5F7FA';
    }
  }

  fileTypeIconColor(): string {
    const type: string = this.fileType.toLowerCase();
    switch (type) {
      case 'pdf':
        return '#F54141';
      case 'doc':
      case 'docx':
        return '#4A7FFF';
      case 'xls':
      case 'xlsx':
        return '#38CFC9';
      case 'ppt':
      case 'pptx':
        return '#FF7E02';
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return '#38CFC9';
      case 'md':
        return '#7330D1';
      default:
        return '#999999';
    }
  }

  extensionDisplay(): string {
    if (this.fileType.length === 0) return '';
    return `.${this.fileType.toLowerCase()}`;
  }
}

@Observed
export class DocumentListModel {
  total: number;
  list: DocumentItemModel[];

  constructor(total: number = 0, list: DocumentItemModel[] = []) {
    this.total = total;
    this.list = list;
  }

  static empty(): DocumentListModel {
    return new DocumentListModel();
  }

  static fromTotalAndList(total: number, list: DocumentItemModel[]): DocumentListModel {
    return new DocumentListModel(total, list);
  }

  appendMore(more: DocumentItemModel[], newTotal: number): DocumentListModel {
    const merged: DocumentItemModel[] = this.list.concat(more);
    return new DocumentListModel(newTotal, merged);
  }

  canLoadMore(): boolean {
    return this.list.length < this.total;
  }
}
