import { AppColors } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { RouterUtil } from '../utils/RouterUtil';
import { LoadingView, ErrorView, EmptyView } from '../components/StateViews';
import { GpaPageModel, SemesterModel, CourseModel, GpaCalculateModel, GpaTargetModel, GpaWarningModel } from '../model/GpaModel';
import { gpaRepository } from '../repository/GpaRepository';
import { SaveCourseRequest } from '../api/ApiService';

@Entry
@Component
struct GpaPage {
  @State pageState: string = 'LOADING';
  @State errorMsg: string = '';
  @State model: GpaPageModel = GpaPageModel.empty();
  @State selectedAlgorithm: string = 'standard';

  @State showAddSemesterDialog: boolean = false;
  @State newSemesterName: string = '';
  @State newSemesterYear: number = 2026;

  @State showCourseDialog: boolean = false;
  @State editingCourseId: number = 0;
  @State courseName: string = '';
  @State courseCredit: number = 4.0;
  @State courseScore: string = '';
  @State courseType: string = '必修';
  @State useGradeMode: boolean = false;
  @State courseGrade: string = 'A';

  @State showDeleteConfirm: boolean = false;
  @State deleteTarget: string = '';
  @State deleteId: number = 0;

  private isLoading: boolean = false;

  aboutToAppear(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    if (this.isLoading) return;
    this.isLoading = true;
    this.pageState = 'LOADING';
    try {
      const semRes = await gpaRepository.loadSemesters();
      if (semRes.code === 401) {
        this.pageState = 'ERROR';
        this.errorMsg = semRes.message || '登录已过期';
        setTimeout(() => RouterUtil.toLogin(), 800);
        return;
      }
      if (!semRes.success || !semRes.data) {
        this.pageState = 'ERROR';
        this.errorMsg = semRes.message || '加载学期列表失败';
        return;
      }

      this.model.updateSemesters(semRes.data);

      if (this.model.semesters.length > 0) {
        await this.loadCoursesAndCalculate(this.model.currentSemesterId);
      } else {
        const emptyCourses: CourseModel[] = [];
        this.model.updateCourses('', emptyCourses);
        this.model.updateCalculate(GpaCalculateModel.empty());
      }

      this.pageState = 'CONTENT';
    } catch (e) {
      this.pageState = 'ERROR';
      this.errorMsg = '加载失败，请重试';
    } finally {
      this.isLoading = false;
    }
  }

  private async loadCoursesAndCalculate(semesterId: number): Promise<void> {
    const courseRes = await gpaRepository.loadCourses(semesterId);
    let courses: CourseModel[] = this.model.courses;
    let semesterName: string = this.model.currentSemesterName;
    if (courseRes.success && courseRes.data) {
      courses = courseRes.data.courses;
      semesterName = courseRes.data.semesterName;
    }

    const calcRes = await gpaRepository.calculateGpa(this.selectedAlgorithm);
    let calc: GpaCalculateModel = this.model.calculate;
    if (calcRes.success && calcRes.data) {
      calc = calcRes.data;
    }

    // 用标准公式本地计算绩点：GPA = Σ(学分×绩点) / Σ学分（仅含已取得绩点的课程）
    // 覆盖后端返回的 currentGpa，确保按用户指定的公式计算
    const localGpa: number = GpaPageModel.computeGpa(courses);
    if (localGpa > 0) {
      calc = new GpaCalculateModel(
        calc.algorithm, localGpa, calc.totalCredits, calc.targets, calc.warnings,
        calc.failedCourses, calc.failedCredits
      );
    }

    // 创建新对象确保 @State 引用变化，触发 ForEach 等 UI 立即刷新
    this.model = new GpaPageModel(
      this.model.semesters, this.model.currentSemesterId, semesterName, courses, calc
    );
  }

  private async onRetry(): Promise<void> {
    await this.loadData();
  }

  private onBack(): void {
    RouterUtil.back();
  }


  private async onSemesterTap(semester: SemesterModel): Promise<void> {
    if (semester.id === this.model.currentSemesterId) return;
    this.model.currentSemesterId = semester.id;
    this.model.currentSemesterName = semester.name;
    await this.loadCoursesAndCalculate(semester.id);
  }

  private onAddSemesterTap(): void {
    const currentYear = new Date().getFullYear();
    this.newSemesterYear = currentYear;
    this.newSemesterName = '';
    this.showAddSemesterDialog = true;
  }

  private async onCreateSemester(): Promise<void> {
    if (this.newSemesterName.trim().length === 0) {
      ToastUtil.show('请输入学期名称');
      return;
    }
    this.showAddSemesterDialog = false;
    ToastUtil.show('创建中...');
    const res = await gpaRepository.createSemester(this.newSemesterName.trim(), this.newSemesterYear);
    if (!res.success) {
      ToastUtil.show(res.message || '创建失败');
      return;
    }
    ToastUtil.show('创建成功');
    await this.loadData();
  }

  private onAddCourseTap(): void {
    if (this.model.currentSemesterId === 0) {
      ToastUtil.show('请先创建学期');
      return;
    }
    this.editingCourseId = 0;
    this.courseName = '';
    this.courseCredit = 4.0;
    this.courseScore = '';
    this.courseType = '必修';
    this.useGradeMode = false;
    this.courseGrade = 'A';
    this.showCourseDialog = true;
  }

  private onEditCourseTap(course: CourseModel): void {
    this.editingCourseId = course.id;
    this.courseName = course.name;
    this.courseCredit = course.credit;
    this.courseScore = course.score > 0 ? course.score.toString() : '';
    this.courseType = course.type;
    this.useGradeMode = course.grade.length > 0;
    this.courseGrade = course.grade || 'A';
    this.showCourseDialog = true;
  }

  private async onSaveCourse(): Promise<void> {
    if (this.courseName.trim().length === 0) {
      ToastUtil.show('请输入课程名称');
      return;
    }
    if (this.courseCredit <= 0) {
      ToastUtil.show('请输入有效学分');
      return;
    }

    const req: SaveCourseRequest = {
      semester_id: this.model.currentSemesterId,
      name: this.courseName.trim(),
      credit: this.courseCredit,
      type: this.courseType
    };

    if (this.editingCourseId > 0) {
      req.id = this.editingCourseId;
    }

    if (this.useGradeMode) {
      req.grade = this.courseGrade;
    } else {
      const score = parseFloat(this.courseScore);
      if (isNaN(score) || score < 0 || score > 100) {
        ToastUtil.show('请输入0-100的成绩');
        return;
      }
      req.score = score;
    }

    this.showCourseDialog = false;
    ToastUtil.show('保存中...');
    const res = await gpaRepository.saveCourse(req);
    if (!res.success) {
      ToastUtil.show(res.message || '保存失败');
      return;
    }
    ToastUtil.show('保存成功');
    await this.loadCoursesAndCalculate(this.model.currentSemesterId);
  }

  private onDeleteCourseTap(course: CourseModel): void {
    this.deleteTarget = 'course';
    this.deleteId = course.id;
    this.showDeleteConfirm = true;
  }

  private onDeleteSemesterTap(semester: SemesterModel): void {
    this.deleteTarget = 'semester';
    this.deleteId = semester.id;
    this.showDeleteConfirm = true;
  }

  private async onConfirmDelete(): Promise<void> {
    this.showDeleteConfirm = false;
    if (this.deleteTarget === 'course') {
      const res = await gpaRepository.deleteCourse(this.deleteId);
      if (!res.success) {
        ToastUtil.show(res.message || '删除失败');
        return;
      }
      ToastUtil.show('删除成功');
      await this.loadCoursesAndCalculate(this.model.currentSemesterId);
    } else if (this.deleteTarget === 'semester') {
      const res = await gpaRepository.deleteSemester(this.deleteId);
      if (!res.success) {
        ToastUtil.show(res.message || '删除失败');
        return;
      }
      ToastUtil.show('删除成功');
      await this.loadData();
    }
  }

  private onAlgorithmChange(algo: string): void {
    this.selectedAlgorithm = algo;
    this.loadCoursesAndCalculate(this.model.currentSemesterId);
  }

  // ========== UI Building ==========
  build() {
    Stack() {
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
          if (this.model.semesters.length === 0) {
            Column() {
              this.EmptyStateCard()
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else {
            Scroll() {
              Column() {
                this.SemesterTabs()
                this.GpaCard()
                if (this.model.calculate.hasWarnings()) {
                  this.WarningCard()
                }
                this.CourseSection()
                Blank(80)
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 16 })
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
          }

          if (this.model.semesters.length > 0) {
            this.FloatingAddButton()
          }
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BG)

      if (this.showAddSemesterDialog) {
        this.AddSemesterDialog()
      }

      if (this.showCourseDialog) {
        this.CourseDialog()
      }

      if (this.showDeleteConfirm) {
        this.DeleteConfirmDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  // ========== Empty State Card ==========
  @Builder
  EmptyStateCard() {
    Column({ space: 20 }) {
      Column() {
        Text('📊')
          .fontSize(48)
      }
      .width(88)
      .height(88)
      .borderRadius(24)
      .backgroundColor('#E6F7F5')
      .justifyContent(FlexAlign.Center)

      Column({ space: 8 }) {
        Text('还没有学期数据')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text('创建你的第一个学期，开始记录课程和绩点')
          .fontSize(14)
          .fontColor(AppColors.TEXT_HINT)
      }
      .alignItems(HorizontalAlign.Center)

      Row() {
        Text('+ 添加学期')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .padding({ left: 32, right: 32, top: 14, bottom: 14 })
      .linearGradient({
        direction: GradientDirection.RightBottom,
        colors: [['#5DD8C8', 0], ['#38CFC9', 1]]
      })
      .borderRadius(24)
      .shadow({ radius: 16, color: 'rgba(56,207,201,0.3)' })
      .onClick(() => this.onAddSemesterTap())
    }
    .padding(32)
    .backgroundColor(Color.White)
    .borderRadius(24)
    .shadow({ radius: 16, color: 'rgba(0,0,0,0.06)' })
    .alignItems(HorizontalAlign.Center)
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

      Text('绩点计算器')
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

  // ========== Semester Tabs ==========
  @Builder
  SemesterTabs() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.model.semesters, (semester: SemesterModel) => {
          this.SemesterTabItem(semester)
        }, (semester: SemesterModel) => `${semester.id}`)

        this.AddSemesterButton()
      }
      .padding({ right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  SemesterTabItem(semester: SemesterModel) {
    Row({ space: 4 }) {
      Text(semester.name)
        .fontSize(14)
        .fontWeight(this.model.currentSemesterId === semester.id ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.model.currentSemesterId === semester.id ? '#38CFC9' : AppColors.TEXT_SECONDARY)
    }
    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
    .backgroundColor(this.model.currentSemesterId === semester.id ? '#E6F7F5' : Color.White)
    .borderRadius(999)
    .border({
      width: 1,
      color: this.model.currentSemesterId === semester.id ? '#38CFC9' : 'rgba(0,0,0,0.06)'
    })
    .onClick(() => this.onSemesterTap(semester))
  }

  @Builder
  AddSemesterButton() {
    Row({ space: 4 }) {
      Text('+ 添加')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#38CFC9')
    }
    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
    .backgroundColor(Color.White)
    .borderRadius(999)
    .border({ width: 1, color: '#38CFC9' })
    .onClick(() => this.onAddSemesterTap())
  }

  // ========== GPA Card ==========
  @Builder
  GpaCard() {
    Column() {
      Column({ space: 6 }) {
        Text(`${this.model.currentSemesterName}学期 · 当前绩点`)
          .fontSize(13)
          .fontColor('rgba(255,255,255,0.85)')
          .width('100%')

        Text(this.model.calculate.currentGpaDisplay())
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .width('100%')
          .margin({ bottom: 4 })

        Row({ space: 12 }) {
          Text(`总学分 ${this.model.calculate.totalCredits.toFixed(1)}`)
            .fontSize(12)
            .fontColor('rgba(255,255,255,0.8)')
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      this.TargetsRow()
    }
    .width('100%')
    .padding(20)
    .borderRadius(20)
    .linearGradient({
      direction: GradientDirection.RightBottom,
      colors: [['#5DD8C8', 0], ['#38CFC9', 1]]
    })
    .shadow({ radius: 16, color: 'rgba(56,207,201,0.3)' })
    .margin({ bottom: 12 })
  }

  @Builder
  TargetsRow() {
    Row({ space: 12 }) {
      ForEach(this.model.calculate.targets, (target: GpaTargetModel) => {
        this.TargetItem(target)
      }, (target: GpaTargetModel) => target.name)
    }
    .width('100%')
    .margin({ top: 16 })
  }

  @Builder
  TargetItem(target: GpaTargetModel) {
    Column({ space: 4 }) {
      Text(target.name)
        .fontSize(12)
        .fontColor('rgba(255,255,255,0.75)')

      Text(target.valueDisplay())
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)

      Text(target.gapDisplay())
        .fontSize(10)
        .fontColor(target.isPassed() ? 'rgba(255,255,255,0.9)' : 'rgba(255,255,255,0.7)')
        .fontWeight(FontWeight.Medium)
    }
    .layoutWeight(1)
    .padding({ left: 8, right: 8, top: 12, bottom: 12 })
    .backgroundColor('rgba(255,255,255,0.2)')
    .borderRadius(12)
    .alignItems(HorizontalAlign.Center)
  }

  // ========== Warning Card ==========
  @Builder
  WarningCard() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text('⚠')
          .fontSize(18)
        Text('挂科预警')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#F54141')
      }
      .width('100%')

      ForEach(this.model.calculate.warnings, (warning: GpaWarningModel) => {
        Text(warning.message)
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
          .width('100%')
          .lineHeight(20)
      }, (warning: GpaWarningModel) => warning.courseName)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFF5F5')
    .borderRadius(16)
    .border({ width: 1, color: '#FFE0E0' })
    .margin({ bottom: 12 })
  }

  // ========== Course Section ==========
  @Builder
  CourseSection() {
    Column({ space: 12 }) {
      Row() {
        Text(`课程列表 · ${this.model.courseCountText()}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text('+ 添加课程')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#38CFC9')
          .onClick(() => this.onAddCourseTap())
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      if (this.model.courses.length === 0) {
        Column() {
          Text('暂无课程，点击"+ 添加课程"开始录入')
            .fontSize(14)
            .fontColor(AppColors.TEXT_HINT)
        }
        .width('100%')
        .padding(32)
        .backgroundColor(Color.White)
        .borderRadius(16)
        .justifyContent(FlexAlign.Center)
      } else {
        Column({ space: 10 }) {
          ForEach(this.model.courses, (course: CourseModel) => {
            this.CourseCard(course)
          }, (course: CourseModel) => `${course.id}`)
        }
      }
    }
    .width('100%')
  }

  @Builder
  CourseCard(course: CourseModel) {
    Row() {
      Column({ space: 6 }) {
        Row({ space: 6 }) {
          Text(course.name)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')

        Row({ space: 8 }) {
          Text(course.creditDisplay())
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
          this.TypeTag(course.type, course.typeColor(), course.typeBgColor())
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column({ space: 4 }) {
        Text(course.scoreDisplay())
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(course.isFailed() ? '#F54141' : AppColors.TEXT_PRIMARY)
          .textAlign(TextAlign.End)

        Row({ space: 4 }) {
          Text(course.gpaDisplay())
            .fontSize(11)
            .fontColor(AppColors.TEXT_HINT)
          Text(`· ${course.gradeDisplay()}`)
            .fontSize(11)
            .fontColor(course.isFailed() ? '#F54141' : AppColors.TEXT_SECONDARY)
        }
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.04)' })
    .border({ width: 1, color: 'rgba(0,0,0,0.04)' })
    .onClick(() => this.onEditCourseTap(course))
    .gesture(
      LongPressGesture({ repeat: false, duration: 500 })
        .onAction(() => {
          this.onDeleteCourseTap(course);
        })
    )
  }

  @Builder
  TypeTag(type: string, textColor: string, bgColor: string) {
    Text(type)
      .fontSize(11)
      .fontWeight(FontWeight.Medium)
      .fontColor(textColor)
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      .backgroundColor(bgColor)
      .borderRadius(6)
  }

  // ========== Floating Add Button ==========
  @Builder
  FloatingAddButton() {
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
      colors: [['#5DD8C8', 0], ['#38CFC9', 1]]
    })
    .borderRadius(28)
    .justifyContent(FlexAlign.Center)
    .shadow({ radius: 20, color: 'rgba(56,207,201,0.35)' })
    .margin({ right: 20, bottom: 24 })
    .alignSelf(ItemAlign.End)
    .onClick(() => this.onAddCourseTap())
  }

  // ========== Add Semester Dialog ==========
  @Builder
  AddSemesterDialog() {
    Column() {
      Column({ space: 20 }) {
        Text('添加学期')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)

        Column({ space: 8 }) {
          Text('学期名称')
            .fontSize(14)
            .fontColor(AppColors.TEXT_SECONDARY)
          TextInput({ placeholder: '如：大二上', text: this.newSemesterName })
            .fontSize(16)
            .fontColor(AppColors.TEXT_PRIMARY)
            .placeholderColor(AppColors.TEXT_HINT)
            .width('100%')
            .height(44)
            .padding({ left: 12, right: 12 })
            .backgroundColor('#F5F7FA')
            .borderRadius(10)
            .onChange((val: string) => {
              this.newSemesterName = val;
            })
        }
        .width('100%')

        Column({ space: 8 }) {
          Text('学年')
            .fontSize(14)
            .fontColor(AppColors.TEXT_SECONDARY)
          Row({ space: 8 }) {
            ForEach([2024, 2025, 2026, 2027], (year: number) => {
              Text(year.toString())
                .fontSize(14)
                .fontWeight(this.newSemesterYear === year ? FontWeight.Bold : FontWeight.Medium)
                .fontColor(this.newSemesterYear === year ? '#38CFC9' : AppColors.TEXT_SECONDARY)
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .backgroundColor(this.newSemesterYear === year ? '#E6F7F5' : '#F5F7FA')
                .borderRadius(8)
                .onClick(() => {
                  this.newSemesterYear = year;
                })
            }, (year: number) => year.toString())
          }
        }
        .width('100%')

        Row({ space: 12 }) {
          Text('取消')
            .fontSize(16)
            .fontColor(AppColors.TEXT_SECONDARY)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding({ top: 12, bottom: 12 })
            .backgroundColor('#F5F7FA')
            .borderRadius(10)
            .onClick(() => {
              this.showAddSemesterDialog = false;
            })

          Text('创建')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding({ top: 12, bottom: 12 })
            .linearGradient({
              direction: GradientDirection.RightBottom,
              colors: [['#5DD8C8', 0], ['#38CFC9', 1]]
            })
            .borderRadius(10)
            .onClick(() => this.onCreateSemester())
        }
        .width('100%')
      }
      .padding(24)
      .backgroundColor(Color.White)
      .borderRadius(20)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(32)
    .backgroundColor('rgba(0,0,0,0.4)')
    .onClick(() => {
      this.showAddSemesterDialog = false;
    })
  }

  // ========== Course Dialog ==========
  @Builder
  CourseDialog() {
    Column() {
      Column({ space: 20 }) {
        Text(this.editingCourseId > 0 ? '编辑课程' : '添加课程')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)

        Column({ space: 8 }) {
          Text('课程名称')
            .fontSize(14)
            .fontColor(AppColors.TEXT_SECONDARY)
          TextInput({ placeholder: '如：高等数学', text: this.courseName })
            .fontSize(16)
            .fontColor(AppColors.TEXT_PRIMARY)
            .placeholderColor(AppColors.TEXT_HINT)
            .width('100%')
            .height(44)
            .padding({ left: 12, right: 12 })
            .backgroundColor('#F5F7FA')
            .borderRadius(10)
            .onChange((val: string) => {
              this.courseName = val;
            })
        }
        .width('100%')

        Column({ space: 8 }) {
          Text('学分')
            .fontSize(14)
            .fontColor(AppColors.TEXT_SECONDARY)
          Row({ space: 6 }) {
            ForEach([0.5, 1, 2, 3, 4, 5, 6], (credit: number) => {
              Text(credit.toString())
                .fontSize(13)
                .fontWeight(this.courseCredit === credit ? FontWeight.Bold : FontWeight.Medium)
                .fontColor(this.courseCredit === credit ? '#38CFC9' : AppColors.TEXT_SECONDARY)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor(this.courseCredit === credit ? '#E6F7F5' : '#F5F7FA')
                .borderRadius(6)
                .onClick(() => {
                  this.courseCredit = credit;
                })
            }, (credit: number) => credit.toString())
          }
        }
        .width('100%')

        Column({ space: 8 }) {
          Text('课程类型')
            .fontSize(14)
            .fontColor(AppColors.TEXT_SECONDARY)
          Row({ space: 8 }) {
            ForEach(['必修', '选修', '公共'], (type: string) => {
              Text(type)
                .fontSize(14)
                .fontWeight(this.courseType === type ? FontWeight.Bold : FontWeight.Medium)
                .fontColor(this.courseType === type ? '#38CFC9' : AppColors.TEXT_SECONDARY)
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .backgroundColor(this.courseType === type ? '#E6F7F5' : '#F5F7FA')
                .borderRadius(8)
                .onClick(() => {
                  this.courseType = type;
                })
            }, (type: string) => type)
          }
        }
        .width('100%')

        Column({ space: 8 }) {
          Row() {
            Text('百分制')
              .fontSize(14)
              .fontWeight(!this.useGradeMode ? FontWeight.Bold : FontWeight.Medium)
              .fontColor(!this.useGradeMode ? '#38CFC9' : AppColors.TEXT_SECONDARY)
              .onClick(() => {
                this.useGradeMode = false;
              })
            Text('等级制')
              .fontSize(14)
              .fontWeight(this.useGradeMode ? FontWeight.Bold : FontWeight.Medium)
              .fontColor(this.useGradeMode ? '#38CFC9' : AppColors.TEXT_SECONDARY)
              .margin({ left: 24 })
              .onClick(() => {
                this.useGradeMode = true;
              })
          }

          if (!this.useGradeMode) {
            TextInput({ placeholder: '输入0-100分', text: this.courseScore })
              .type(InputType.Number)
              .fontSize(16)
              .fontColor(AppColors.TEXT_PRIMARY)
              .placeholderColor(AppColors.TEXT_HINT)
              .width('100%')
              .height(44)
              .padding({ left: 12, right: 12 })
              .backgroundColor('#F5F7FA')
              .borderRadius(10)
              .onChange((val: string) => {
                this.courseScore = val;
              })
          } else {
            Scroll() {
              Row({ space: 6 }) {
                ForEach(['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D', 'F'], (grade: string) => {
                  Text(grade)
                    .fontSize(13)
                    .fontWeight(this.courseGrade === grade ? FontWeight.Bold : FontWeight.Medium)
                    .fontColor(this.courseGrade === grade ? '#38CFC9' : AppColors.TEXT_SECONDARY)
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .backgroundColor(this.courseGrade === grade ? '#E6F7F5' : '#F5F7FA')
                    .borderRadius(6)
                    .onClick(() => {
                      this.courseGrade = grade;
                    })
                }, (grade: string) => grade)
              }
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .width('100%')
          }
        }
        .width('100%')

        Row({ space: 12 }) {
          Text('取消')
            .fontSize(16)
            .fontColor(AppColors.TEXT_SECONDARY)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding({ top: 12, bottom: 12 })
            .backgroundColor('#F5F7FA')
            .borderRadius(10)
            .onClick(() => {
              this.showCourseDialog = false;
            })

          Text('保存')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding({ top: 12, bottom: 12 })
            .linearGradient({
              direction: GradientDirection.RightBottom,
              colors: [['#5DD8C8', 0], ['#38CFC9', 1]]
            })
            .borderRadius(10)
            .onClick(() => this.onSaveCourse())
        }
        .width('100%')
      }
      .padding(24)
      .backgroundColor(Color.White)
      .borderRadius(20)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(32)
    .backgroundColor('rgba(0,0,0,0.4)')
    .onClick(() => {
      this.showCourseDialog = false;
    })
  }

  // ========== Delete Confirm Dialog ==========
  @Builder
  DeleteConfirmDialog() {
    Column() {
      Column({ space: 20 }) {
        Text('确认删除')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)

        Text('删除后将无法恢复，确定要继续吗？')
          .fontSize(14)
          .fontColor(AppColors.TEXT_SECONDARY)

        Row({ space: 12 }) {
          Text('取消')
            .fontSize(16)
            .fontColor(AppColors.TEXT_SECONDARY)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding({ top: 12, bottom: 12 })
            .backgroundColor('#F5F7FA')
            .borderRadius(10)
            .onClick(() => {
              this.showDeleteConfirm = false;
            })

          Text('删除')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding({ top: 12, bottom: 12 })
            .backgroundColor('#F54141')
            .borderRadius(10)
            .onClick(() => this.onConfirmDelete())
        }
        .width('100%')
      }
      .padding(24)
      .backgroundColor(Color.White)
      .borderRadius(20)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(32)
    .backgroundColor('rgba(0,0,0,0.4)')
  }
}
