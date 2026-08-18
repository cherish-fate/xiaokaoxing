import { AppColors } from '../utils/Constants';
import { RouterUtil } from '../utils/RouterUtil';
import { ToastUtil } from '../utils/ToastUtil';
import { DateUtil } from '../utils/DateUtil';

@Entry
@Component
struct DailyQuestionResultPage {
  @State questionId: number = 0;
  @State selected: string = '';
  @State isCorrect: boolean = false;
  @State correctAnswer: string = '';
  @State explanation: string = '';
  @State earnedPoints: number = 0;
  @State wrongBookAdded: boolean = false;
  @State subject: string = '';
  @State question: string = '';
  @State options: string[] = [];
  @State difficulty: number = 1;
  @State streak: number = 0;

  aboutToAppear(): void {
    const params: Record<string, Object> = RouterUtil.getParams();
    this.questionId = parseInt(String(params['questionId'] || '0')) || 0;
    this.selected = String(params['selected'] || '');
    this.isCorrect = String(params['isCorrect'] || '0') === '1';
    this.correctAnswer = String(params['correctAnswer'] || '');
    this.explanation = String(params['explanation'] || '');
    this.earnedPoints = parseInt(String(params['earnedPoints'] || '0')) || 0;
    this.wrongBookAdded = String(params['wrongBookAdded'] || '0') === '1';
    this.subject = String(params['subject'] || '');
    this.question = String(params['question'] || '');
    const optsStr: string = String(params['options'] || '');
    this.options = optsStr ? optsStr.split('||') : [];
    this.difficulty = parseInt(String(params['difficulty'] || '1')) || 1;
    this.streak = parseInt(String(params['streak'] || '0')) || 0;
  }

  private onBack(): void {
    RouterUtil.back();
  }

  private onWrongBookTap(): void {
    ToastUtil.show('错题本功能即将上线');
  }

  build() {
    Column() {
      this.Header();

      Scroll() {
        Column() {
          this.MetaTags();
          this.QuestionStem();
          this.OptionsList();
          this.ExplanationCard();
          if (!this.isCorrect && this.wrongBookAdded) {
            this.WrongBookNotice();
          }
          this.ResultCard();
          Blank(40)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
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
        Row() {
          Text('‹')
            .fontSize(24)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
        .width(40)
        .height(40)
        .backgroundColor('rgba(255,255,255,0.15)')
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.onBack())

        Blank()

        Row({ space: 6 }) {
          Text('🔥')
            .fontSize(14)
          Text(`连续答题 ${this.streak} 天`)
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
        Text(`📅 ${DateUtil.todayChinese()}`)
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

      Text(this.question)
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
        Text(this.subject || '未知科目')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E84F4F')
      }
      .padding({ left: 8, right: 8, top: 5, bottom: 5 })
      .backgroundColor('#FFEBEB')
      .borderRadius(999)

      Row({ space: 4 }) {
        Text(this.getDifficultyStars())
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#38CFC9')
        Text(this.getDifficultyLabel())
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

  private getDifficultyStars(): string {
    const total: number = 3;
    const filled: number = Math.min(this.difficulty, total);
    let result: string = '';
    for (let i: number = 0; i < total; i++) {
      result += i < filled ? '★' : '☆';
    }
    return result;
  }

  private getDifficultyLabel(): string {
    if (this.difficulty <= 1) return '简单';
    if (this.difficulty === 2) return '中等';
    return '困难';
  }

  // ========== Question Stem ==========
  @Builder
  QuestionStem() {
    Column({ space: 12 }) {
      Text(this.question)
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
      ForEach(this.options, (option: string, index: number) => {
        this.OptionResultItem(option, index)
      }, (option: string, index: number) => `${index}_${option}`)
    }
    .width('100%')
  }

  private getOptionLabel(index: number): string {
    const labels: string[] = ['A', 'B', 'C', 'D'];
    return labels[index] || String(index + 1);
  }

  private isShowWrong(label: string): boolean {
    return this.selected === label && !this.isCorrect;
  }

  private isShowCorrect(label: string): boolean {
    return this.correctAnswer === label;
  }

  @Builder
  OptionResultItem(option: string, index: number) {
    Row({ space: 12 }) {
      Row() {
        if (this.isShowWrong(this.getOptionLabel(index)) || this.isShowCorrect(this.getOptionLabel(index))) {
          Text(this.getOptionLabel(index))
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        } else {
          Text(this.getOptionLabel(index))
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_HINT)
        }
      }
      .width(34)
      .height(34)
      .backgroundColor(
        this.isShowWrong(this.getOptionLabel(index)) || this.isShowCorrect(this.getOptionLabel(index))
          ? (this.isShowWrong(this.getOptionLabel(index)) ? '#F54141' : '#38CFC9')
          : '#F1F3F7'
      )
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)

      Text(option)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .lineHeight(24)
        .layoutWeight(1)

      if (this.isShowWrong(this.getOptionLabel(index))) {
        Text('✕')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#F54141')
      } else if (this.isShowCorrect(this.getOptionLabel(index))) {
        Text('✓')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#38CFC9')
      }
    }
    .width('100%')
    .padding(16)
    .padding({ right: 48 })
    .backgroundColor(
      this.isShowWrong(this.getOptionLabel(index)) ? '#FFF0F0' :
      this.isShowCorrect(this.getOptionLabel(index)) ? '#E6F7F5' :
      Color.White
    )
    .borderRadius(18)
    .border({
      width: 1.5,
      color: this.isShowWrong(this.getOptionLabel(index)) ? '#F54141' :
             this.isShowCorrect(this.getOptionLabel(index)) ? '#38CFC9' :
             'rgba(0,0,0,0.06)'
    })
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.03)' })
  }

  // ========== Explanation Card ==========
  @Builder
  ExplanationCard() {
    Row() {
      Column()
        .width(4)
        .height('100%')
        .backgroundColor('#38CFC9')
        .borderRadius(2)

      Column() {
        Row({ space: 8 }) {
          Text('💡')
            .fontSize(14)
          Text('答案解析')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#38CFC9')
        }
        .width('100%')
        .margin({ bottom: 8 })

        Text(this.explanation || '暂无解析')
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
          .lineHeight(22)
          .width('100%')
      }
      .layoutWeight(1)
      .padding({ left: 14, right: 14, top: 14, bottom: 14 })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(16)
    .border({ width: 1, color: 'rgba(0,0,0,0.06)' })
    .margin({ top: 20 })
  }

  // ========== Wrong Book Notice ==========
  @Builder
  WrongBookNotice() {
    Row({ space: 6 }) {
      Text('⭐')
        .fontSize(12)
      Text('本题已自动加入错题本 · 点击查看')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#E84F4F')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .backgroundColor('#FFF5E6')
    .borderRadius(12)
    .justifyContent(FlexAlign.Center)
    .margin({ top: 12 })
    .onClick(() => this.onWrongBookTap())
  }

  // ========== Result Card ==========
  @Builder
  ResultCard() {
    Column({ space: 6 }) {
      if (this.isCorrect) {
        Text('🎉')
          .fontSize(36)
        Text('答对啦！+' + this.earnedPoints + ' 积分')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#38CFC9')
        Text('继续保持，今天状态不错！')
          .fontSize(13)
          .fontColor(AppColors.TEXT_HINT)
      } else {
        Text('🎯')
          .fontSize(36)
        Text('答错啦！正确答案是 ' + (this.correctAnswer || ''))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E84F4F')
        Text('没关系，错题已收录 · 明天继续加油')
          .fontSize(13)
          .fontColor(AppColors.TEXT_HINT)
      }
    }
    .width('100%')
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .border({ width: 1, color: 'rgba(0,0,0,0.06)' })
    .alignItems(HorizontalAlign.Center)
    .margin({ top: 16 })
  }
}
