import { router } from '@kit.ArkUI'

@Entry
@Component
struct Index {
  build() {
   Stack() {
       Scroll() {
         Column({space:20}){
           Column({ space: 8 }) {
             Stack({ alignContent: Alignment.Center }) {
               Image($r('app.media.background'))
                 .width(90)
                 .height(90)
                 .backgroundColor('#4A7FFF')
                 .borderRadius(24)
                 .shadow({ radius: 12, color: 'rgba(74, 127, 255, 0.3)', offsetY: 6 })
               Image($r('app.media.index_star'))
                 .width(50)
             }

             Text($r('app.string.app_title'))
               .fontSize(36)
               .fontWeight(FontWeight.Bold)
               .fontColor('#1A1A1A')
             Text($r('app.string.app_subtitle1'))
               .fontSize(14)
               .fontColor('#666666')
             Text($r('app.string.app_subtitle2'))
               .fontSize(14)
               .fontColor('#666666')
           }

           Row({ space: 40 }) {
             Column({ space: 4 }) {
               Text($r('app.string.stat_students'))
                 .fontSize(28)
                 .fontWeight(FontWeight.Bold)
                 .fontColor('#4A7FFF')
               Text($r('app.string.stat_students_label'))
                 .fontSize(12)
                 .fontColor('#999999')
             }

             Column({ space: 4 }) {
               Text($r('app.string.stat_schools'))
                 .fontSize(28)
                 .fontWeight(FontWeight.Bold)
                 .fontColor('#4A7FFF')
               Text($r('app.string.stat_schools_label'))
                 .fontSize(12)
                 .fontColor('#999999')
             }

             Column({ space: 4 }) {
               Text($r('app.string.stat_rate'))
                 .fontSize(28)
                 .fontWeight(FontWeight.Bold)
                 .fontColor('#4A7FFF')
               Text($r('app.string.stat_rate_label'))
                 .fontSize(12)
                 .fontColor('#999999')
             }
           }

           Column({ space: 12 }) {
             FeatureCard({
               title: $r('app.string.feature1_title'),
               desc: $r('app.string.feature1_desc'),
               bgColor: '#E8F0FF',
               image:$r('app.media.index_book'),
               iamgecolor: '#ff4181ff'
             })
             FeatureCard({
               title: $r('app.string.feature2_title'),
               desc: $r('app.string.feature2_desc'),
               bgColor: '#FFF7ED',
               image:$r('app.media.index_energy'),
               iamgecolor: '#ffff7e02'
             })
             FeatureCard({
               title: $r('app.string.feature3_title'),
               desc: $r('app.string.feature3_desc'),
               bgColor: '#E6F7F5',
               image:$r('app.media.index_up'),
               iamgecolor: '#ff38cfc9'
             })
             FeatureCard({
               title: $r('app.string.feature4_title'),
               desc: $r('app.string.feature4_desc'),
               bgColor: '#F5F0FF',
               image:$r('app.media.index_person'),
               iamgecolor: '#ff7330d1'
             })
             FeatureCard({
               title: $r('app.string.feature5_title'),
               desc: $r('app.string.feature5_desc'),
               bgColor: '#FFF0F0',
               image:$r('app.media.index_right'),
               iamgecolor: '#fff54141'
             })
           }

           Column({ space: 12 }) {
             Button($r('app.string.btn_start'))
               .width('100%')
               .height(52)
               .backgroundColor('#4A7FFF')
               .borderRadius(20)
               .fontSize(16)
               .fontWeight(FontWeight.Medium)
               .fontColor(Color.White)
               .shadow({ radius: 8, color: 'rgba(74, 127, 255, 0.4)', offsetY: 4 })
               .onClick(()=>{
                 router.replaceUrl({ url: 'pages/RegisterPage' })
               })
             Button($r('app.string.btn_login'))
               .width('100%')
               .height(52)
               .backgroundColor('#FFFFFF')
               .borderRadius(20)
               .fontSize(16)
               .fontWeight(FontWeight.Medium)
               .fontColor('#1A1A1A')
               .border({ width: 1, color: '#E5E7EB' })
               .onClick(()=>{
                 router.replaceUrl({ url: 'pages/Login' })
               })
           }

           Row() {
             Text('注册即代表同意')
               .fontSize(12)
               .fontColor('#999999')
             Text('《用户服务协议》')
               .fontSize(12)
               .fontColor('#4A7FFF')
             Text('和')
               .fontSize(12)
               .fontColor('#999999')
             Text('《隐私政策》')
               .fontSize(12)
               .fontColor('#4A7FFF')
           }
        }
         .padding({left:20,right:20})
         .width('100%')
         .alignItems(HorizontalAlign.Center)
       }
       .align(Alignment.Top)
       .scrollBar(BarState.Off)
       .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}

@Component
struct FeatureCard {
  private title: Resource = $r('app.string.feature1_title')
  private desc: Resource = $r('app.string.feature1_desc')
  private bgColor: string = '#E8F0FF'
  private image:Resource=$r('app.media.index_book')
  private iamgecolor:string='#ffffff'
  build() {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(48)
          .height(48)
          .backgroundColor(this.bgColor)
          .borderRadius(12)
        Image(this.image)
          .width(20)
          .fillColor(this.iamgecolor)
      }
      Column({ space: 4 }) {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .width('100%')
        Text(this.desc)
          .fontSize(12)
          .fontColor('#999999')
          .width('100%')
      }
      .margin({ left: 12 })
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 14,
      bottom: 14
    })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 10, color: 'rgba(0, 0, 0, 0.08)', offsetX: 0, offsetY: 5 })
  }
}


