import { AppColors, AppSize } from '../utils/Constants';
import { HotTeamModel } from '../model/CommunityHomeModel';
import { RouterUtil } from '../utils/RouterUtil';
import { RouteUrls } from '../utils/RouteUrls';

@Component
export struct HotTeamCard {
  @Link hotTeams: HotTeamModel[];

  @Builder
  TeamItem(team: HotTeamModel) {
    Column({ space: 14 }) {
      Row() {
        Column() {
          Image(team.subject === '高等数学' ? $r('app.media.community_math') :
            team.subject === '大学英语' ? $r('app.media.community_english') :
            team.subject === '线性代数' ? $r('app.media.community_xiandai') :
            team.subject === '数据结构' ? $r('app.media.community_data') : $r('app.media.community_teamicon'))
            .width(22)
        }
        .width(48)
        .height(48)
        .backgroundColor('#E8F0FF')
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 4 }) {
          Row({ space: 6 }) {
            Text(team.name)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_PRIMARY)
          }
          Row({space:5}){
            Text(team.subject)
              .fontSize(11)
              .fontColor(AppColors.PRIMARY)
              .backgroundColor('#E8F0FF')
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .borderRadius(10)
            Row({ space: 3 }) {
              Circle()
                .width(6)
                .height(6)
                .fill(AppColors.SUCCESS)
              Text(`${team.onlineCount}人在线`)
                .fontSize(11)
                .fontColor(AppColors.SUCCESS)
            }
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .width('100%')
       Divider()
      Row() {
        this.TeamStat(`${team.memberCount}/${team.maxMembers}`, '成员', '#ff1c1c1c')
        this.TeamStat(`${team.checkinRate.toFixed(0)}%`, '打卡率', '#ff70ccc8')
        this.TeamStat(`${team.totalCheckins}`, '总打卡', '#ffeb8734')
      }
      .width('100%')

      if (!team.isCreator) {
        Button('+ 申请加入（需审核）')
          .width('100%')
          .height(40)
          .backgroundColor(AppColors.PRIMARY)
          .fontSize(14)
          .fontColor(Color.White)
          .borderRadius(10)
          .onClick(() => RouterUtil.push(RouteUrls.COMMUNITY_TEAM_DETAIL,
            { "id": team.id }))
      } else {
        Row({ space: 6 }) {
          Image($r('app.media.community_shalou'))
            .width(20)
          Text('审核中')
            .fontSize(13)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .justifyContent(FlexAlign.Center)
        .borderRadius(15)
        .backgroundColor('#ffe7e6e6')
        .width('100%')
        .padding({ top: 10, bottom: 10 })
      }
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .backgroundColor('#FAFBFD')
    .borderRadius(AppSize.RADIUS_MD)
    .onClick(() => RouterUtil.push(RouteUrls.COMMUNITY_TEAM_DETAIL,
      { "id": team.id }))
  }

  @Builder
  TeamStat(value: string, label: string,color:string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(12)
        .fontColor(AppColors.TEXT_HINT)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      Row() {
        Row({ space: 4 }) {
          Image($r('app.media.community_team'))
            .width(20)
          Text('热门备考小队')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .layoutWeight(1)

        Row({ space: 2 }) {
          Text('创建')
            .fontSize(13)
            .fontColor(AppColors.PRIMARY)
          Text('>')
            .fontSize(13)
            .fontColor(AppColors.PRIMARY)
        }
        .onClick(() => RouterUtil.push(RouteUrls.COMMUNITY_TEAM))
      }
      .width('100%')
      .margin({ bottom: 12 })

      Column({ space: 12 }) {
        if (this.hotTeams.length === 0) {
          Column({ space: 6 }) {
            Text('暂无小队')
              .fontSize(14)
              .fontColor(AppColors.TEXT_HINT)
            Text('去创建第一个小队吧')
              .fontSize(12)
              .fontColor(AppColors.TEXT_HINT)
          }
          .width('100%')
          .padding({ top: 24, bottom: 24 })
        } else {
          ForEach(this.hotTeams, (team: HotTeamModel) => {
            this.TeamItem(team)
          })
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }
}
