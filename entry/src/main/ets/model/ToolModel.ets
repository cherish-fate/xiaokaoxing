import {
  DailyQuestionHome,
  NoteTagCount,
  NotesHomeSummary,
  GpaHomeSummary,
  DocumentsHomeSummary,
  BookmarksHomeSummary,
  ToolboxHomeResponse
} from '../api/ApiService';

@Observed
export class DailyQuestionHomeModel {
  hasAnswered: boolean;
  question: string;
  subject: string;
  date: string;

  constructor(hasAnswered: boolean = false, question: string = '', subject: string = '', date: string = '') {
    this.hasAnswered = hasAnswered;
    this.question = question;
    this.subject = subject;
    this.date = date;
  }

  static empty(): DailyQuestionHomeModel {
    return new DailyQuestionHomeModel(false, '', '', '');
  }

  static fromApi(src: DailyQuestionHome): DailyQuestionHomeModel {
    return new DailyQuestionHomeModel(
      !!src.has_answered,
      src.question || '',
      src.subject || '',
      src.date || ''
    );
  }
}

@Observed
export class NoteTagCountModel {
  name: string;
  count: number;

  constructor(name: string = '', count: number = 0) {
    this.name = name;
    this.count = count;
  }

  static fromApi(src: NoteTagCount): NoteTagCountModel {
    return new NoteTagCountModel(src.name || '', src.count || 0);
  }
}

@Observed
export class NotesHomeSummaryModel {
  count: number;
  tags: NoteTagCountModel[];

  constructor(count: number = 0, tags: NoteTagCountModel[] = []) {
    this.count = count;
    this.tags = tags;
  }

  static empty(): NotesHomeSummaryModel {
    return new NotesHomeSummaryModel(0, []);
  }

  static fromApi(src: NotesHomeSummary): NotesHomeSummaryModel {
    const tagsList: NoteTagCountModel[] = (src.tags || []).map(t => NoteTagCountModel.fromApi(t));
    return new NotesHomeSummaryModel(src.count || 0, tagsList);
  }
}

@Observed
export class GpaHomeSummaryModel {
  current: number;
  trend: number;
  semester: string;

  constructor(current: number = 0, trend: number = 0, semester: string = '') {
    this.current = current;
    this.trend = trend;
    this.semester = semester;
  }

  static empty(): GpaHomeSummaryModel {
    return new GpaHomeSummaryModel(0, 0, '');
  }

  static fromApi(src: GpaHomeSummary): GpaHomeSummaryModel {
    return new GpaHomeSummaryModel(src.current || 0, src.trend || 0, src.semester || '');
  }

  currentDisplay(): string {
    return this.current > 0 ? this.current.toFixed(2) : '--';
  }

  trendDisplay(): string {
    if (this.trend === 0) return '';
    const sign: string = this.trend > 0 ? '↑' : '↓';
    return `${sign} ${Math.abs(this.trend).toFixed(2)} vs 上学期`;
  }

  trendColor(): string {
    return this.trend >= 0 ? '#38CFC9' : '#F54141';
  }
}

@Observed
export class DocumentsHomeSummaryModel {
  total: number;
  categories: NoteTagCountModel[];

  constructor(total: number = 0, categories: NoteTagCountModel[] = []) {
    this.total = total;
    this.categories = categories;
  }

  static empty(): DocumentsHomeSummaryModel {
    return new DocumentsHomeSummaryModel(0, []);
  }

  static fromApi(src: DocumentsHomeSummary): DocumentsHomeSummaryModel {
    const cats: NoteTagCountModel[] = [];
    if (src.categories) {
      const keys: string[] = Object.keys(src.categories);
      for (let i: number = 0; i < keys.length; i++) {
        cats.push(new NoteTagCountModel(keys[i], src.categories[keys[i]] || 0));
      }
    }
    return new DocumentsHomeSummaryModel(src.total || 0, cats);
  }
}

@Observed
export class BookmarksHomeSummaryModel {
  total: number;

  constructor(total: number = 0) {
    this.total = total;
  }

  static empty(): BookmarksHomeSummaryModel {
    return new BookmarksHomeSummaryModel(0);
  }

  static fromApi(src: BookmarksHomeSummary): BookmarksHomeSummaryModel {
    return new BookmarksHomeSummaryModel(src.total || 0);
  }
}

@Observed
export class ToolPageModel {
  dailyQuestion: DailyQuestionHomeModel;
  notes: NotesHomeSummaryModel;
  gpa: GpaHomeSummaryModel;
  documents: DocumentsHomeSummaryModel;
  bookmarks: BookmarksHomeSummaryModel;

  constructor(
    dailyQuestion: DailyQuestionHomeModel,
    notes: NotesHomeSummaryModel,
    gpa: GpaHomeSummaryModel,
    documents: DocumentsHomeSummaryModel,
    bookmarks: BookmarksHomeSummaryModel
  ) {
    this.dailyQuestion = dailyQuestion;
    this.notes = notes;
    this.gpa = gpa;
    this.documents = documents;
    this.bookmarks = bookmarks;
  }

  static empty(): ToolPageModel {
    return new ToolPageModel(
      DailyQuestionHomeModel.empty(),
      NotesHomeSummaryModel.empty(),
      GpaHomeSummaryModel.empty(),
      DocumentsHomeSummaryModel.empty(),
      BookmarksHomeSummaryModel.empty()
    );
  }

  static fromApi(src: ToolboxHomeResponse): ToolPageModel {
    const dq: DailyQuestionHomeModel = DailyQuestionHomeModel.fromApi(src.daily_question);
    const notes: NotesHomeSummaryModel = NotesHomeSummaryModel.fromApi(src.notes);
    const gpa: GpaHomeSummaryModel = GpaHomeSummaryModel.fromApi(src.gpa);
    const docs: DocumentsHomeSummaryModel = DocumentsHomeSummaryModel.fromApi(src.documents);
    const bm: BookmarksHomeSummaryModel = BookmarksHomeSummaryModel.fromApi(src.bookmarks);
    return new ToolPageModel(dq, notes, gpa, docs, bm);
  }
}
