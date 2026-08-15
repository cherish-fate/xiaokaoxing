import {
  SemesterItem,
  CourseItem,
  GpaTarget,
  GpaWarning,
  GpaCalculateResponse,
  CourseListResponse
} from '../api/ApiService';

@Observed
export class SemesterModel {
  id: number;
  name: string;
  year: number;
  courseCount: number;

  constructor(id: number = 0, name: string = '', year: number = 0, courseCount: number = 0) {
    this.id = id;
    this.name = name;
    this.year = year;
    this.courseCount = courseCount;
  }

  static empty(): SemesterModel {
    return new SemesterModel();
  }

  static fromApi(src: SemesterItem): SemesterModel {
    return new SemesterModel(
      src.id || 0,
      src.name || '',
      src.year || 0,
      src.course_count || 0
    );
  }
}

@Observed
export class CourseModel {
  id: number;
  name: string;
  credit: number;
  score: number;
  grade: string;
  type: string;
  gpa: number;

  constructor(
    id: number = 0,
    name: string = '',
    credit: number = 0,
    score: number = 0,
    grade: string = '',
    type: string = '',
    gpa: number = 0
  ) {
    this.id = id;
    this.name = name;
    this.credit = credit;
    this.score = score;
    this.grade = grade;
    this.type = type;
    this.gpa = gpa;
  }

  static empty(): CourseModel {
    return new CourseModel();
  }

  static fromApi(src: CourseItem): CourseModel {
    return new CourseModel(
      src.id || 0,
      src.name || '',
      src.credit || 0,
      src.score || 0,
      src.grade || '',
      src.type || '',
      src.gpa || 0
    );
  }

  creditDisplay(): string {
    return `${this.credit} 学分`;
  }

  scoreDisplay(): string {
    return this.score > 0 ? this.score.toString() : '--';
  }

  gradeDisplay(): string {
    if (this.grade.length > 0) return this.grade;
    if (this.score >= 90) return 'A';
    if (this.score >= 80) return 'B';
    if (this.score >= 70) return 'C';
    if (this.score >= 60) return 'D';
    return '不及格';
  }

  isFailed(): boolean {
    return this.score > 0 && this.score < 60;
  }

  typeColor(): string {
    switch (this.type) {
      case '必修':
        return '#FF6B6B';
      case '选修':
        return '#4A7FFF';
      case '公共':
        return '#38CFC9';
      default:
        return '#999999';
    }
  }

  typeBgColor(): string {
    switch (this.type) {
      case '必修':
        return '#FFF0F0';
      case '选修':
        return '#E8F0FF';
      case '公共':
        return '#E6F7F5';
      default:
        return '#F5F7FA';
    }
  }

  gpaDisplay(): string {
    return this.gpa > 0 ? `绩点 ${this.gpa.toFixed(1)}` : '--';
  }
}

@Observed
export class GpaTargetModel {
  name: string;
  value: number;
  gap: number;
  status: string;

  constructor(name: string = '', value: number = 0, gap: number = 0, status: string = '') {
    this.name = name;
    this.value = value;
    this.gap = gap;
    this.status = status;
  }

  static empty(): GpaTargetModel {
    return new GpaTargetModel();
  }

  static fromApi(name: string, src: GpaTarget): GpaTargetModel {
    return new GpaTargetModel(
      name,
      src.value || 0,
      src.gap || 0,
      src.status || ''
    );
  }

  valueDisplay(): string {
    return this.value.toFixed(2);
  }

  gapDisplay(): string {
    if (this.status === '已超出' || this.status === '达标') {
      return '已超出 ✓';
    }
    if (this.gap < 0) {
      return `还差 ${Math.abs(this.gap).toFixed(2)}`;
    }
    return `${this.gap.toFixed(2)}`;
  }

  isPassed(): boolean {
    return this.status === '已超出' || this.status === '达标';
  }
}

@Observed
export class GpaWarningModel {
  courseName: string;
  score: number;
  credit: number;
  message: string;

  constructor(
    courseName: string = '',
    score: number = 0,
    credit: number = 0,
    message: string = ''
  ) {
    this.courseName = courseName;
    this.score = score;
    this.credit = credit;
    this.message = message;
  }

  static empty(): GpaWarningModel {
    return new GpaWarningModel();
  }

  static fromApi(src: GpaWarning): GpaWarningModel {
    return new GpaWarningModel(
      src.course_name || '',
      src.score || 0,
      src.credit || 0,
      src.message || ''
    );
  }
}

@Observed
export class GpaCalculateModel {
  algorithm: string;
  currentGpa: number;
  totalCredits: number;
  targets: GpaTargetModel[];
  warnings: GpaWarningModel[];
  failedCourses: number;
  failedCredits: number;

  constructor(
    algorithm: string = '',
    currentGpa: number = 0,
    totalCredits: number = 0,
    targets: GpaTargetModel[] = [],
    warnings: GpaWarningModel[] = [],
    failedCourses: number = 0,
    failedCredits: number = 0
  ) {
    this.algorithm = algorithm;
    this.currentGpa = currentGpa;
    this.totalCredits = totalCredits;
    this.targets = targets;
    this.warnings = warnings;
    this.failedCourses = failedCourses;
    this.failedCredits = failedCredits;
  }

  static empty(): GpaCalculateModel {
    return new GpaCalculateModel();
  }

  static fromApi(src: GpaCalculateResponse): GpaCalculateModel {
    const targetsList: GpaTargetModel[] = [];
    if (src.targets) {
      const keys: string[] = Object.keys(src.targets);
      for (let i: number = 0; i < keys.length; i++) {
        targetsList.push(GpaTargetModel.fromApi(keys[i], src.targets[keys[i]]));
      }
    }
    const warningsList: GpaWarningModel[] = (src.warnings || []).map(w => GpaWarningModel.fromApi(w));
    return new GpaCalculateModel(
      src.algorithm || '',
      src.current_gpa || 0,
      src.total_credits || 0,
      targetsList,
      warningsList,
      src.failed_courses || 0,
      src.failed_credits || 0
    );
  }

  currentGpaDisplay(): string {
    return this.currentGpa > 0 ? this.currentGpa.toFixed(2) : '--';
  }

  hasWarnings(): boolean {
    return this.warnings.length > 0;
  }

  failedCountText(): string {
    return `挂科 ${this.failedCourses} 门`;
  }
}

@Observed
export class GpaPageModel {
  semesters: SemesterModel[];
  currentSemesterId: number;
  currentSemesterName: string;
  courses: CourseModel[];
  calculate: GpaCalculateModel;

  constructor(
    semesters: SemesterModel[] = [],
    currentSemesterId: number = 0,
    currentSemesterName: string = '',
    courses: CourseModel[] = [],
    calculate: GpaCalculateModel = GpaCalculateModel.empty()
  ) {
    this.semesters = semesters;
    this.currentSemesterId = currentSemesterId;
    this.currentSemesterName = currentSemesterName;
    this.courses = courses;
    this.calculate = calculate;
  }

  static empty(): GpaPageModel {
    return new GpaPageModel();
  }

  updateSemesters(list: SemesterModel[]): void {
    this.semesters = list;
    if (list.length > 0 && this.currentSemesterId === 0) {
      this.currentSemesterId = list[0].id;
      this.currentSemesterName = list[0].name;
    }
  }

  updateCourses(semesterName: string, list: CourseModel[]): void {
    this.currentSemesterName = semesterName;
    this.courses = list;
  }

  updateCalculate(calc: GpaCalculateModel): void {
    this.calculate = calc;
  }

  courseCountText(): string {
    return `${this.courses.length} 门`;
  }
}
