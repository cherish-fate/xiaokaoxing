export class CommunityResourceModel {
  id: number;
  title: string;
  author: string;
  createdAt: string;
  status: string;

  constructor(
    id: number,
    title: string,
    author: string,
    createdAt: string,
    status: string
  ) {
    this.id = id;
    this.title = title;
    this.author = author;
    this.createdAt = createdAt;
    this.status = status;
  }

  isApproved(): boolean {
    return this.status === '已上线';
  }

  isPending(): boolean {
    return this.status === '审核中' || this.status === '待审核';
  }

  statusChipBg(): string {
    if (this.isApproved()) return '#E6F7F5';
    return '#FFF7ED';
  }

  statusChipColor(): string {
    if (this.isApproved()) return '#38CFC9';
    return '#FF7E02';
  }

  statusChipText(): string {
    if (this.isApproved()) return '✓ 已审核';
    return '⏳ 审核中';
  }

  iconEmoji(): string {
    const t = this.title.toLowerCase();
    if (t.indexOf('.pdf') >= 0) return '📄';
    if (t.indexOf('.zip') >= 0 || t.indexOf('.rar') >= 0) return '📊';
    if (t.indexOf('.doc') >= 0 || t.indexOf('.docx') >= 0) return '📝';
    if (t.indexOf('.ppt') >= 0) return '📽️';
    return '📁';
  }

  iconBg(): string {
    const t = this.title.toLowerCase();
    if (t.indexOf('.pdf') >= 0) return '#E8F0FF';
    if (t.indexOf('.zip') >= 0 || t.indexOf('.rar') >= 0) return '#F5F0FF';
    if (t.indexOf('.doc') >= 0) return '#FFF7ED';
    if (t.indexOf('.ppt') >= 0) return '#FFF0F0';
    return '#E6F7F5';
  }

  iconColor(): string {
    const t = this.title.toLowerCase();
    if (t.indexOf('.pdf') >= 0) return '#4A7FFF';
    if (t.indexOf('.zip') >= 0) return '#7330D1';
    if (t.indexOf('.doc') >= 0) return '#FF7E02';
    if (t.indexOf('.ppt') >= 0) return '#F54141';
    return '#38CFC9';
  }
}

export class MyUploadItemModel {
  id: number;
  title: string;
  category: string;
  type: string;
  status: string;
  createdAt: string;
  viewCount: number;
  rejectReason: string;

  constructor(
    id: number,
    title: string,
    category: string,
    type: string,
    status: string,
    createdAt: string,
    viewCount: number,
    rejectReason: string = ''
  ) {
    this.id = id;
    this.title = title;
    this.category = category;
    this.type = type;
    this.status = status;
    this.createdAt = createdAt;
    this.viewCount = viewCount;
    this.rejectReason = rejectReason;
  }

  isApproved(): boolean {
    return this.status === '已上线' || this.status === '审核通过';
  }

  isPending(): boolean {
    return this.status === '审核中' || this.status === '待审核';
  }

  isRejected(): boolean {
    return this.status === '未通过' || this.status === '未审核';
  }

  hasRejectReason(): boolean {
    return !!this.rejectReason && this.rejectReason.length > 0;
  }

  statusChipBg(): string {
    if (this.isApproved()) return '#E6F7F5';
    if (this.isRejected()) return '#FFF0F0';
    return '#FFF7ED';
  }

  statusChipColor(): string {
    if (this.isApproved()) return '#38CFC9';
    if (this.isRejected()) return '#F54141';
    return '#FF7E02';
  }

  statusChipText(): string {
    if (this.isApproved()) return '✓ 已上线';
    if (this.isRejected()) return '✕ 未通过';
    return '⏳ 审核中';
  }

  categoryTagBg(): string {
    if (this.category.indexOf('真题') >= 0) return '#E8F0FF';
    if (this.category.indexOf('提纲') >= 0) return '#FFF7ED';
    if (this.category.indexOf('考点') >= 0) return '#E6F7F5';
    if (this.category.indexOf('题库') >= 0) return '#F5F0FF';
    return '#E8F0FF';
  }

  categoryTagColor(): string {
    if (this.category.indexOf('真题') >= 0) return '#4A7FFF';
    if (this.category.indexOf('提纲') >= 0) return '#FF7E02';
    if (this.category.indexOf('考点') >= 0) return '#38CFC9';
    if (this.category.indexOf('题库') >= 0) return '#7330D1';
    return '#4A7FFF';
  }

  iconEmoji(): string {
    const t = this.title.toLowerCase();
    if (t.indexOf('.pdf') >= 0) return '📄';
    if (t.indexOf('.zip') >= 0 || t.indexOf('.rar') >= 0) return '📊';
    if (t.indexOf('.doc') >= 0) return '📝';
    if (t.indexOf('.ppt') >= 0) return '📽️';
    return '📁';
  }

  iconBg(): string {
    const t = this.title.toLowerCase();
    if (t.indexOf('.pdf') >= 0) return '#E8F0FF';
    if (t.indexOf('.zip') >= 0) return '#F5F0FF';
    if (t.indexOf('.doc') >= 0) return '#FFF7ED';
    if (t.indexOf('.ppt') >= 0) return '#FFF0F0';
    return '#E6F7F5';
  }

  iconColor(): string {
    const t = this.title.toLowerCase();
    if (t.indexOf('.pdf') >= 0) return '#4A7FFF';
    if (t.indexOf('.zip') >= 0) return '#7330D1';
    if (t.indexOf('.doc') >= 0) return '#FF7E02';
    if (t.indexOf('.ppt') >= 0) return '#F54141';
    return '#38CFC9';
  }
}

export class MyUploadListModel {
  list: MyUploadItemModel[];

  constructor(list: MyUploadItemModel[]) {
    this.list = list;
  }

  static empty(): MyUploadListModel {
    return new MyUploadListModel([]);
  }
}

export interface UploadResourceRequest {
  file: ArrayBuffer;
  fileName: string;
  title: string;
  subject: string;
  type: string;
  category: string;
  description?: string;
}

// Repository.uploadResource 专用入参：带fileBuffer/fileSizeBytes
export interface UploadResourceParams {
  fileBuffer: ArrayBuffer;
  fileName: string;
  fileSizeBytes: number;
  title: string;
  subject: string;
  type: string;
  category: string;
  description?: string;
}

// 页面提交参数：Repository.uploadResource() 专用入参
export interface UploadResourceArgs {
  title: string;
  description?: string;
  fileUrl: string;
  subject?: string;
  tags?: string[];
}

export class UploadResourceResultModel {
  id: number;
  title: string;
  status: string;
  createdAt: string;
  message: string;

  constructor(
    id: number,
    title: string,
    status: string,
    createdAt: string,
    message: string = ''
  ) {
    this.id = id;
    this.title = title;
    this.status = status;
    this.createdAt = createdAt;
    this.message = message;
  }
}
