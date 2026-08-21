@Entry
@Component
struct AvatarPage {
  build() {
    Column() {
      Image('http://10.0.2.2:3000/uploads/avatar_1787107040287396600.jpg')
        .width(120)
        .height(120)
        .borderRadius(60)
        .objectFit(ImageFit.Cover)
        .onError((err) => {
          console.error(`图片加载失败: ${JSON.stringify(err)}`);
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}