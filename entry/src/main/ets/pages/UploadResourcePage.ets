import { AppColors, AppSize } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { Logger } from '../utils/Logger';
import { RouterUtil } from '../utils/RouterUtil';
import { sharedResourceRepository } from '../repository/SharedResourceRepository';
import {
  MyUploadListModel,
  MyUploadItemModel,
  UploadResourceParams
} from '../model/SharedResourceModel';

const TAG = 'UploadResourcePage';
const SUBJECT_LIST = ['高等数学', '大学英语', '线性代数', '数据结构', '大学物理', '计算机组成原理'];
const TYPE_LIST = ['真题试卷', '复习提纲', '课件考点', '自测题库'];

@Entry
@Component
struct UploadResourcePage {
  @State pageState: string = 'LOADING';
  @State tab: number = 0; // 0上传 1我的上传
  @State myUploads: MyUploadItemModel[] = [];

  // 表单
  @State formTitle: string = '';
  @State formSubject: string = '';
  @State formType: string = '';
  @State formDesc: string = '';
  @State fileName: string = '';
  @State fileBuffer: ArrayBuffer | null = null;
  @State fileSizeBytes: number = 0;
  @State uploading: boolean = false;

  async aboutToAppear(): Promise<void> {
    this.pageState = 'LOADING';
    await this.loadUploads();
    this.pageState = 'CONTENT';
  }

  private async loadUploads() {
    const res = await sharedResourceRepository.loadMyUploads();
    if (res.code === 401) { setTimeout(() => RouterUtil.toLogin(), 800); return; }
    if (res.success && res.data) this.myUploads = res.data.list;
  }

  // 文件选择（使用 picker 或 file 系统，这里提供占位实现）
  private async pickFile() {
    try {
      // 鸿蒙原生 ArkTS 文件选择示例（简化）
      // 由于需要 @ohos.file.picker ，这里给用户提示，实际项目中需集成
      ToastUtil.show('请选择要上传的文件（PDF/Word/PPT/ZIP ≤ 50MB）');
      Logger.info(TAG, 'pickFile invoked - 需要根据真机环境接入file picker');
    } catch (e) {
      Logger.error(TAG, 'pickFile error', e as Error);
      ToastUtil.show('选择文件失败');
    }
  }

  // 供外部/测试调用的 setFile 方法：
  public setLocalFile(name: string, buffer: ArrayBuffer, size: number) {
    this.fileName = name;
    this.fileBuffer = buffer;
    this.fileSizeBytes = size;
  }

  private clearForm() {
    this.formTitle = '';
    this.formSubject = '';
    this.formType = '';
    this.formDesc = '';
    this.fileName = '';
    this.fileBuffer = null;
    this.fileSizeBytes = 0;
  }

  private async doUpload() {
    if (this.uploading) return;
    if (!this.fileBuffer) { ToastUtil.show('请选择要上传的文件'); return; }
    if (!this.formTitle.trim()) { ToastUtil.show('请填写资料标题'); return; }
    if (!this.formSubject.trim()) { ToastUtil.show('请输入科目'); return; }
    if (!this.formType) { ToastUtil.show('请选择资料类型'); return; }
    this.uploading = true;
    const params: UploadResourceParams = {
      fileBuffer: this.fileBuffer,
      fileName: this.fileName,
      fileSizeBytes: this.fileSizeBytes,
      title: this.formTitle,
      subject: this.formSubject,
      type: this.formType,
      category: this.formType,
      description: this.formDesc || undefined
    };
    const res = await sharedResourceRepository.uploadResource(params);
    this.uploading = false;
    if (!res.success || !res.data) {
      ToastUtil.show(res.message || '上传失败');
      return;
    }
    ToastUtil.show(res.message || '上传成功');
    this.clearForm();
    await this.loadUploads();
    this.tab = 1;
  }

  @Builder
  Header() {
    Stack({ alignContent: Alignment.Top }) {
      Column() {
        Row({ space: 6 }) {
          Image($r('app.media.community_upload'))
            .width(23)
          Text('共享资料')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .justifyContent(FlexAlign.Center)

        Text('优质资料汇入备考中心，帮助更多同学')
          .fontSize(12)
          .fontColor(AppColors.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
          .padding({ bottom: 10, top: 2 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      Row() {
        Image($r('app.media.examDetail_back'))
          .width(22)
          .height(22)
          .onClick(() => RouterUtil.back())
      }
      .width('100%')
      .padding({ left: AppSize.PADDING_MD, top: 2 })
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .padding({ top: 14 })
    .backgroundColor(Color.White)
  }


  @Builder
  UploadGuideCard() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Text('📋')
          .fontSize(16)
        Text('资料上传说明')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#ff70ccca')
      }
      .width('100%')

      Column({ space: 4 }) {
        Text('1. 选择文件并填写信息 → 2. 提交审核（1-2工作日）')
          .fontSize(12.5)
          .fontColor('#ff676767')
          .width('100%')
        Text('3. 审核通过后汇入备考中心资源库 → 4. 获得积分 ✨')
          .fontSize(12.5)
          .fontColor('#ff676767')
          .width('100%')
      }
      .width('100%')
      .padding({ left: 4 })
    }
    .width('100%')
    .padding(AppSize.PADDING_MD)
    .backgroundColor('#ffeaf6f5')
    .borderRadius(AppSize.RADIUS_LG)
  }

  @Builder
  Tabs() {
    Row() {
      this.TabBtn('上传资料', 0)
      this.TabBtn(`我的上传 (${this.myUploads.length})`, 1)
    }
    .width('100%')
    .padding(5)
    .backgroundColor(Color.White)
  }

  @Builder
  TabBtn(label: string, index: number) {
    Text(label)
      .fontSize(14)
      .fontWeight(this.tab === index ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(this.tab === index ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
      .width('50%').height(38).textAlign(TextAlign.Center)
      .backgroundColor(this.tab === index ? '#E8F0FF' : Color.Transparent)
      .borderRadius(AppSize.RADIUS_MD)
      .onClick(() => { this.tab = index; })
  }

  @Builder
  FilePickerCard() {
    Column({ space: 20 }) {
      Row({ space: 10 }) {
        Text('📁')
          .fontSize(20)
        Text('选择文件')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
      }
      .width('100%')

      if (this.fileName.length > 0) {
        Row({ space: 12 }) {
          Column() { Text('📄').fontSize(22).textAlign(TextAlign.Center) }
            .width(52).height(52)
            .backgroundColor(this.fileIconBg())
            .borderRadius(AppSize.RADIUS_MD)
            .justifyContent(FlexAlign.Center)
          Column({ space: 6 }) {
            Text(this.fileName)
              .fontSize(14)
              .fontColor(AppColors.TEXT_PRIMARY)
              .fontWeight(FontWeight.Medium)
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
            Text(`${(this.fileSizeBytes / 1024 / 1024).toFixed(2)} MB`)
              .fontSize(12).fontColor(AppColors.TEXT_HINT)
          }
          .layoutWeight(1).alignItems(HorizontalAlign.Start)
          Text('✕')
            .fontSize(20)
            .fontColor(AppColors.TEXT_HINT)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .onClick(() => { this.fileBuffer = null; this.fileName = ''; this.fileSizeBytes = 0; })
        }
        .width('100%')
        .padding(AppSize.PADDING_MD)
        .backgroundColor('#FAFBFD')
        .borderRadius(AppSize.RADIUS_LG)
      } else {
        Column({ space: 14 }) {
          Column() {
            Text('📄')
              .fontSize(42)
              .fontColor('#BBBFC9')
          }
          .width(72)
          .height(72)
          .backgroundColor('#F7F8FA')
          .borderRadius(18)
          .justifyContent(FlexAlign.Center)
          .margin({ top: 10 })

          Column({ space: 6 }) {
            Text('点击选择文件')
              .fontSize(16)
              .fontColor(AppColors.TEXT_PRIMARY)
              .fontWeight(FontWeight.Medium)
            Text('PDF / Word / PPT / ZIP，≤50MB')
              .fontSize(13)
              .fontColor(AppColors.TEXT_HINT)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding({ top: 28, bottom: 32 })
        .border({
          width: {
            left: 1.5,
            right: 1.5,
            top: 1.5,
            bottom: 1.5
          },
          color: '#E5E7EB',
          radius: AppSize.RADIUS_LG,
          style: BorderStyle.Dashed
        })
        .onClick(() => this.pickFile())
      }
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_XL)
    .shadow({ radius: 1, color: '#1A000000', offsetX: 0, offsetY: 1 })
  }

  private fileIconBg(): string {
    const t = this.fileName.toLowerCase();
    if (t.indexOf('.pdf') >= 0) return '#E8F0FF';
    if (t.indexOf('.zip') >= 0 || t.indexOf('.rar') >= 0) return '#F5F0FF';
    if (t.indexOf('.doc') >= 0) return '#FFF7ED';
    if (t.indexOf('.ppt') >= 0) return '#FFF0F0';
    return '#F2F5FA';
  }

  @Builder
  FormCard() {
    Column({ space: 22 }) {
      Row({ space: 10 }) {
        Text('📝')
          .fontSize(20)
        Text('资料信息')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
      }
      .width('100%')

      // 资料标题
      Column({ space: 10 }) {
        Row({ space: 2 }) {
          Text('资料标题')
            .fontSize(14.5)
            .fontColor(AppColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
          Text('*')
            .fontColor(AppColors.DANGER)
            .fontSize(14.5)
        }
        .width('100%')

        TextInput({ placeholder: '例：高数（上）期末复习提纲' })
          .fontSize(14)
          .width('100%')
          .height(50)
          .backgroundColor('#F5F7FA')
          .borderRadius(AppSize.RADIUS_LG)
          .padding({ left: 16, right: 16 })
          .placeholderColor('#B5BAC4')
          .onChange((v: string) => { this.formTitle = v.substring(0, 50); })
      }
      .width('100%')

      // 科目（手动输入）
      Column({ space: 10 }) {
        Row({ space: 2 }) {
          Text('科目')
            .fontSize(14.5)
            .fontColor(AppColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
          Text('*')
            .fontColor(AppColors.DANGER)
            .fontSize(14.5)
        }
        .width('100%')

        TextInput({ placeholder: '请输入科目，如：高等数学' })
          .fontSize(14)
          .width('100%')
          .height(50)
          .backgroundColor('#F5F7FA')
          .borderRadius(AppSize.RADIUS_LG)
          .padding({ left: 16, right: 16 })
          .placeholderColor('#B5BAC4')
          .onChange((v: string) => { this.formSubject = v.substring(0, 20); })
      }
      .width('100%')

      // 分类标签
      Column({ space: 12 }) {
        Row({ space: 6 }) {
          Text('分类标签')
            .fontSize(14.5)
            .fontColor(AppColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
          Text('*')
            .fontColor(AppColors.DANGER)
            .fontSize(14.5)
        }
        .width('100%')

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(TYPE_LIST, (t: string) => {
            Row({ space: 4 }) {
              Text(t)
                .fontSize(14)
                .fontColor(this.formType === t ? AppColors.PRIMARY : AppColors.TEXT_PRIMARY)
            }
            .padding({ left: 18, right: 18, top: 10, bottom: 10 })
            .margin({ right: 12, bottom: 12 })
            .backgroundColor(this.formType === t ? '#E8F0FF' : '#F5F7FA')
            .borderRadius(14)
            .onClick(() => { this.formType = t; })
          })
        }
        .width('100%')
      }
      .width('100%')

      // 资料简介
      Column({ space: 10 }) {
        Row({ space: 6 }) {
          Text('资料简介')
            .fontSize(14.5)
            .fontColor(AppColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
          Text('（可选）')
            .fontSize(12.5)
            .fontColor(AppColors.TEXT_HINT)
        }
        .width('100%')

        TextArea({ placeholder: '简要说明资料内容...' })
          .fontSize(14)
          .width('100%')
          .height(96)
          .backgroundColor('#F5F7FA')
          .borderRadius(AppSize.RADIUS_LG)
          .padding(AppSize.PADDING_MD)
          .placeholderColor('#B5BAC4')
          .onChange((v: string) => { this.formDesc = v.substring(0, 200); })
          .margin({ bottom: 4 })
      }
      .width('100%')
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_XL)
    .shadow({ radius: 1, color: '#1A000000', offsetX: 0, offsetY: 1 })
  }

  @Builder
  SubmitButton() {
    Button(this.uploading ? '上传中...' : '提交审核')
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .height(56)
      .width('100%')
      .backgroundColor(AppColors.PRIMARY)
      .borderRadius(28)
      .enabled(!this.uploading)
      .onClick(() => this.doUpload())
  }

  @Builder
  UploadItem(u: MyUploadItemModel) {
    Row({ space: 14 }) {
      // 左侧文件类型图标
      Column() {
        Text(u.iconEmoji())
          .fontSize(24)
          .textAlign(TextAlign.Center)
      }
      .width(52)
      .height(52)
      .backgroundColor(u.iconBg())
      .borderRadius(AppSize.RADIUS_MD)
      .justifyContent(FlexAlign.Center)

      // 中间信息
      Column({ space: 6 }) {
        Text(u.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row({ space: 6 }) {
          Text(u.category)
            .fontSize(12)
            .fontColor(u.categoryTagColor())
            .backgroundColor(u.categoryTagBg())
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(9)
          Text('·')
            .fontSize(12)
            .fontColor(AppColors.TEXT_HINT)
          Text(u.createdAt)
            .fontSize(12)
            .fontColor(AppColors.TEXT_HINT)
          Blank()
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 右侧状态标签
      Row({ space: 4 }) {
        Text(u.isApproved() ? '✓' : u.isPending() ? '⏳' : '✕')
          .fontSize(12)
          .fontColor(u.statusChipColor())
        Text(u.isApproved() ? '已上线' : u.isPending() ? '审核中' : '未通过')
          .fontSize(12)
          .fontColor(u.statusChipColor())
      }
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .backgroundColor(u.statusChipBg())
      .borderRadius(14)
    }
    .width('100%')
    .padding(AppSize.PADDING_MD)
  }

  @Builder
  UploadList() {
    Column({ space: 0 }) {
      if (this.myUploads.length === 0) {
        Column({ space: 8 }) {
          Text('📂').fontSize(40)
          Text('还没有上传记录').fontSize(15).fontColor(AppColors.TEXT_HINT)
          Text('切换到「上传资料」，分享你的第一份资料吧')
            .fontSize(12.5).fontColor(AppColors.TEXT_HINT)
        }
        .width('100%')
        .padding({ top: 48, bottom: 48 })
      } else {
        ForEach(this.myUploads, (u: MyUploadItemModel) => {
          this.UploadItem(u)
          if (u.hasRejectReason()) {
            Row({ space: 6 }) {
              Text('💬')
                .fontSize(12)
              Text(`未通过原因：${u.rejectReason}`)
                .fontSize(12)
                .fontColor(AppColors.DANGER)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 14, right: 14, top: 10, bottom: 12 })
            .margin({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD, bottom: 6 })
            .backgroundColor('#FFF5F5')
            .borderRadius(AppSize.RADIUS_MD)
          }
          if (this.myUploads.indexOf(u) !== this.myUploads.length - 1) {
            Divider()
              .color(AppColors.DIVIDER)
              .margin({ left: 82, right: AppSize.PADDING_MD })
          }
        })
      }
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
  }

  @Builder
  MyUploadCard() {
    Column({ space: 0 }) {
      // 我的上传记录标题
      Row({ space: 10 }) {
        Text('📋')
          .fontSize(20)
        Text('我的上传记录')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: AppSize.PADDING_LG, right: AppSize.PADDING_LG, top: AppSize.PADDING_LG, bottom: 12 })

      this.UploadList()
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_XL)
    .shadow({ radius: 1, color: '#1A000000', offsetX: 0, offsetY: 1 })
  }

  build() {
    Column() {
      this.Header()
      if (this.pageState === 'LOADING') {
        Column() { LoadingProgress().color(AppColors.PRIMARY) }
          .layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
          .backgroundColor(AppColors.BG)
      } else {
        Column() {
          // Tab切换栏（保留现有）
          this.Tabs()
        }
        .backgroundColor(AppColors.BG)

        Scroll() {
          Column({ space: 14 }) {
            if (this.tab === 0) {
              // 上传资料Tab
              this.UploadGuideCard()
              this.FilePickerCard()
              this.FormCard()
              Column() {
                this.SubmitButton()
              }
              .width('100%')
              .padding({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD, bottom: AppSize.PADDING_LG })
            } else {
              // 我的上传Tab
              this.MyUploadCard()
            }
          }
          .width('100%')
          .padding({ top: AppSize.PADDING_SM, bottom: AppSize.PADDING_LG })
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .backgroundColor(AppColors.BG)
        .padding({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD })
      }
    }
    .width('100%').height('100%')
  }
}
