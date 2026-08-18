import { AppColors } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { DateUtil } from '../utils/DateUtil';
import { DailyQuestionModel, DailyQuestionResultModel } from '../model/DailyQuestionModel';
import { DailyAnsweredRecord } from '../api/ApiService';
import { dailyQuestionRepository } from '../repository/DailyQuestionRepository';
import { LoadingView, ErrorView } from '../components/StateViews';
import { RouterUtil } from '../utils/RouterUtil';
import { RouteUrls } from '../utils/RouteUrls';

@Entry
@Component
struct DailyQuestionPage {
  @State pageState: string = 'LOADING';
  @State errorMsg: string = '';
  @State model: DailyQuestionModel = DailyQuestionModel.empty();
  @State selectedOption: string = '';
  @State submitting: boolean = false;

  async aboutToAppear(): Promise<void> {
    this.pageState = 'LOADING';
    await this.loadData();
  }

  private async loadData(): Promise<void> {
    const res = await dailyQuestionRepository.loadTodayQuestion();
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
    if (this.model.hasAnswered && this.model.record) {
      const record: DailyAnsweredRecord = this.model.record;
      const optionsStr: string = this.model.options.join('||');
      const params: Record<string, Object> = {
        'questionId': String(this.model.id),
        'selected': record.selected,
        'isCorrect': record.is_correct ? '1' : '0',
        'correctAnswer': '',
        'explanation': record.explanation || '',
        'earnedPoints': '0',
        'wrongBookAdded': '0',
        'subject': this.model.subject,
        'question': this.model.question,
        'options': optionsStr,
        'difficulty': String(this.model.difficulty),
        'streak': String(this.model.streak)
      };
      this.pageState = 'CONTENT';
      setTimeout(() => {
        RouterUtil.pushWithParams(RouteUrls.DAILY_QUESTION_RESULT, params);
      }, 300);
      return;
    }
    this.selectedOption = '';
    this.pageState = 'CONTENT';
  }

  private async onRetry(): Promise<void> {
    this.pageState = 'LOADING';
    await this.loadData();
  }

  private onSelectOption(label: string): void {
    if (this.submitting) return;
    if (this.model.hasAnswered) {
      ToastUtil.show('今日已答题');
      return;
    }
    this.selectedOption = label;
  }

  private async onSubmit(): Promise<void> {
    if (this.submitting) return;
    if (!this.selectedOption) {
      ToastUtil.show('请先选择一个选项');
      return;
    }
    this.submitting = true;
    const res = await dailyQuestionRepository.submitAnswer(
      this.model.id,
      this.selectedOption
    );
    this.submitting = false;
    if (!res.success || !res.data) {
      ToastUtil.show(res.message || '提交失败');
      return;
    }
    const result: DailyQuestionResultModel = res.data;
    const optionsStr: string = this.model.options.join('||');
    const params: Record<string, Object> = {
      'questionId': String(this.model.id),
      'selected': this.selectedOption,
      'isCorrect': result.isCorrect ? '1' : '0',
      'correctAnswer': result.correctAnswer,
      'explanation': result.explanation,
      'earnedPoints': String(result.earnedPoints),
      'wrongBookAdded': result.wrongBookAdded ? '1' : '0',
      'subject': this.model.subject,
      'question': this.model.question,
      'options': optionsStr,
      'difficulty': String(this.model.difficulty),
      'streak': String(result.streak)
    };
    RouterUtil.pushWithParams(RouteUrls.DAILY_QUESTION_RESULT, params);
  }

  private onBack(): void {
    RouterUtil.back();
  }


  build() {
    Column() {
      this.Header();

      Stack({ alignContent: Alignment.Bottom }) {
        if (this.pageState === 'LOADING') {
          Column() {
            LoadingView({ message: '加载中…' })
          }
          .width('100%')
          .height('100%')
        } else if (this.pageState === 'ERROR') {
          Column() {
            ErrorView({ message: this.errorMsg, onRetry: () => this.onRetry() })
          }
          .width('100%')
          .height('100%')
        } else {
          Scroll() {
            Column() {
              this.MetaTags();
              this.QuestionStem();
              this.OptionsList();
              Blank(100)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16 })
          }
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)
        }

        this.FooterBar();
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG)
  }

  // ========== Header ==========
  @Builder
  Header() {
    Column() {
      Row() {
          Image($r('app.media.examDetail_back'))
            .width(40)
            .height(40)
            .padding(10)
            .backgroundColor(AppColors.CARD)
            .borderRadius(20)
            .onClick(() => this.onBack())

        Blank()

        Row({ space: 6 }) {
          Text('🔥')
            .fontSize(14)
          Text(`连续答题 ${this.model.streak} 天`)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor('rgba(255,255,255,0.18)')
        .borderRadius(999)
      }
      .width('100%')
      .height(44)

      Row({ space: 6 }) {
        Text(DateUtil.todayChinese())
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.85)')
          .fontWeight(FontWeight.Medium)
        Text('·')
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.6)')
        Text('每日一问')
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.85)')
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .margin({ top: 4 })

      Text(this.model.question || '题目加载中…')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .lineHeight(30)
        .width('100%')
        .margin({ top: 10 })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 8, bottom: 24 })
    .linearGradient({
      direction: GradientDirection.RightBottom,
      colors: [['#E84F4F', 0], ['#F28C3A', 1]]
    })
  }

  // ========== Meta Tags ==========
  @Builder
  MetaTags() {
    Row({ space: 8 }) {
      Row({ space: 4 }) {
        Text(this.model.subject || '未知科目')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E84F4F')
      }
      .padding({ left: 8, right: 8, top: 5, bottom: 5 })
      .backgroundColor('#FFEBEB')
      .borderRadius(999)

      Row({ space: 4 }) {
        Text(this.model.difficultyStars())
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#38CFC9')
        Text(this.model.difficultyLabel())
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#38CFC9')
      }
      .padding({ left: 8, right: 8, top: 5, bottom: 5 })
      .backgroundColor('#E6F7F5')
      .borderRadius(999)
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  // ========== Question Stem ==========
  @Builder
  QuestionStem() {
    Column({ space: 12 }) {
      Text(this.model.question)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .lineHeight(26)
        .width('100%')
    }
    .width('100%')
    .padding(18)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.04)' })
    .border({ width: 1, color: 'rgba(0,0,0,0.04)' })
    .margin({ bottom: 20 })
  }

  // ========== Options List ==========
  @Builder
  OptionsList() {
    Column({ space: 12 }) {
      ForEach(this.model.options, (option: string, index: number) => {
        this.OptionItem(option, index)
      }, (option: string, index: number) => `${index}_${option}`)
    }
    .width('100%')
  }

  private getOptionLabel(index: number): string {
    const labels: string[] = ['A', 'B', 'C', 'D', 'E', 'F'];
    return labels[index] || String(index + 1);
  }

  private isOptionSelected(index: number): boolean {
    return this.selectedOption === this.getOptionLabel(index);
  }

  @Builder
  OptionItem(option: string, index: number) {
    Row({ space: 12 }) {
      if (this.isOptionSelected(index)) {
        Row() {
          Text(this.getOptionLabel(index))
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width(34)
        .height(34)
        .backgroundColor('#F28C3A')
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
      } else {
        Row() {
          Text('')
        }
        .width(22)
        .height(22)
        .borderRadius(11)
        .border({ width: 2, color: '#CCD1DB' })
        .backgroundColor(Color.White)
        .margin({ left: 6, top: 6 })
      }

      Text(option)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .lineHeight(24)
        .layoutWeight(1)
    }
    .width('100%')
    .padding(16)
    .padding({ right: 48 })
    .backgroundColor(this.isOptionSelected(index) ? '#FFF5E6' : Color.White)
    .borderRadius(18)
    .border({
      width: 1.5,
      color: this.isOptionSelected(index) ? '#F28C3A' : 'rgba(0,0,0,0.06)'
    })
    .shadow({
      radius: this.isOptionSelected(index) ? 20 : 12,
      color: this.isOptionSelected(index) ? 'rgba(242,140,58,0.15)' : 'rgba(0,0,0,0.03)'
    })
    .onClick(() => this.onSelectOption(this.getOptionLabel(index)))
  }

  // ========== Footer ==========
  @Builder
  FooterBar() {
    Row({ space: 10 }) {
      Row({ space: 10 }) {
        Text('确认提交')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        Text('→')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
      }
      .layoutWeight(1)
      .height(50)
      .linearGradient({
        direction: GradientDirection.RightBottom,
        colors: [['#E84F4F', 0], ['#F28C3A', 1]]
      })
      .borderRadius(16)
      .justifyContent(FlexAlign.Center)
      .shadow({ radius: 22, color: 'rgba(242,100,58,0.3)' })
      .opacity(this.submitting ? 0.6 : 1)
      .onClick(() => this.onSubmit())
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 20 })
    .backgroundColor('rgba(244,246,250,0.95)')
  }
}
