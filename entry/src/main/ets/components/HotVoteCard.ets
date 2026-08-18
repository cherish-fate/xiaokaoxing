import { AppColors, AppSize } from '../utils/Constants';
import { HotVoteModel } from '../model/CommunityHomeModel';
import { RouterUtil } from '../utils/RouterUtil';
import { RouteUrls } from '../utils/RouteUrls';

@Component
export struct HotVoteCard {
  @Link hotVotes: HotVoteModel[];

  @Builder
  StarRow(count: number) {
    Row({ space: 2 }) {
      ForEach([1, 2, 3, 4, 5], (level: number) => {
        Text(level <= count ? '★' : '☆')
          .fontSize(11)
          .fontColor(level <= count ? AppColors.WARNING : '#D5D9E0')
      })
    }
  }

  @Builder
  VoteItem(vote: HotVoteModel) {
    Column({ space: 10 }) {
      Row() {
        Row({ space: 6 }) {
          Text(vote.subject)
            .fontSize(11)
            .fontColor(AppColors.PRIMARY)
            .backgroundColor('#E8F0FF')
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(10)
          Text(vote.title)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .layoutWeight(1)

        Text(`${vote.voteCount}票`)
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .width('100%')

      Row({ space: 8 }) {
        Row()
          .width(`${Math.min(vote.confidenceWidth(), 100)}%`)
          .height(8)
          .backgroundColor(AppColors.PRIMARY)
          .borderRadius(4)
        this.StarRow(vote.stars)
        Text(`${vote.computedConfidence()}%认为会考`)
          .fontSize(11)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  build() {
    Column() {
      Row() {
        Row({ space: 4 }) {
          Text('🏆')
            .fontSize(18)
          Text('本校本周高频考点 TOP3')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .layoutWeight(1)
        .onClick(() => RouterUtil.push(RouteUrls.COMMUNITY_VOTE))
      }
      .width('100%')
      .margin({ bottom: 8 })

      Column() {
        ForEach(this.hotVotes, (vote: HotVoteModel, index: number) => {
          Column() {
            if (index > 0) {
              Divider()
                .color(AppColors.DIVIDER)
                .strokeWidth(1)
            }
            this.VoteItem(vote)
          }
          .width('100%')
        })
      }
      .width('100%')

      Row() {
        Text('+')
          .fontSize(18)
          .fontColor(AppColors.PRIMARY)
        Text('创建新考点投票')
          .fontSize(14)
          .fontColor(AppColors.PRIMARY)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ top: 14, bottom: 14 })
      .margin({ top: 4 })
      .backgroundColor('#F5F7FA')
      .borderRadius(15)
      .onClick(() => RouterUtil.push(RouteUrls.COMMUNITY_VOTE))
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }
}
