import {
  apiService,
  ApiResponse,
  MyUploadListResponse,
  MyUploadItem,
  UploadResourceResponse
} from '../api/ApiService';
import {
  MyUploadListModel,
  MyUploadItemModel,
  UploadResourceParams,
  UploadResourceResultModel
} from '../model/SharedResourceModel';
import { ResultUtil, AsyncResult } from '../utils/ResultUtil';
import { Logger } from '../utils/Logger';

const TAG = 'SharedResourceRepository';
const ALLOWED_EXT = ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'zip'];
const MAX_SIZE_BYTES = 50 * 1024 * 1024;

export class SharedResourceRepository {
  private mapMyUploadItem(i: MyUploadItem): MyUploadItemModel {
    return new MyUploadItemModel(
      i.id,
      i.title || '',
      i.category || '',
      i.type || '',
      i.status || '',
      i.created_at || '',
      i.view_count || 0,
      i.reject_reason || ''
    );
  }

  private validateFile(fileName: string, fileSizeBytes: number): string | null {
    const lowerName = fileName.toLowerCase();
    const idx = lowerName.lastIndexOf('.');
    if (idx <= 0 || idx === lowerName.length - 1) {
      return '无法识别文件后缀名，请选择有效文件';
    }
    const ext = lowerName.substring(idx + 1);
    if (ALLOWED_EXT.indexOf(ext) < 0) {
      return '不支持的文件格式，仅支持PDF/Word/PPT/ZIP';
    }
    if (fileSizeBytes > MAX_SIZE_BYTES) {
      return '文件大小超过50MB限制';
    }
    return null;
  }

  async loadMyUploads(): Promise<AsyncResult<MyUploadListModel>> {
    const res: ApiResponse<MyUploadListResponse> = await apiService.fetchMyUploads();
    if (res.code === 401) {
      return ResultUtil.fail<MyUploadListModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<MyUploadListModel>(
        res.code, res.message || '我的上传记录加载失败'
      );
    }
    const list = (res.data.list || []).map(i => this.mapMyUploadItem(i));
    return ResultUtil.success(new MyUploadListModel(list));
  }

  async uploadResource(params: UploadResourceParams): Promise<AsyncResult<UploadResourceResultModel>> {
    if (!params.fileBuffer) {
      return ResultUtil.fail<UploadResourceResultModel>(400, '请选择要上传的文件');
    }
    if (!params.title || params.title.trim().length === 0) {
      return ResultUtil.fail<UploadResourceResultModel>(400, '请填写资料标题');
    }
    if (params.title.length > 50) {
      return ResultUtil.fail<UploadResourceResultModel>(400, '标题不能超过50字');
    }
    if (!params.subject) {
      return ResultUtil.fail<UploadResourceResultModel>(400, '请选择科目');
    }
    if (!params.type) {
      return ResultUtil.fail<UploadResourceResultModel>(400, '请选择资料类型');
    }
    const validateErr = this.validateFile(params.fileName, params.fileSizeBytes);
    if (validateErr) {
      return ResultUtil.fail<UploadResourceResultModel>(400, validateErr);
    }
    const fields: Record<string, string> = {};
    fields['title'] = params.title.trim();
    fields['subject'] = params.subject;
    fields['type'] = params.type;
    fields['category'] = params.category || params.type;
    if (params.description) {
      fields['description'] = params.description.length > 200
        ? params.description.substring(0, 200) : params.description;
    }
    const res: ApiResponse<UploadResourceResponse> = await apiService.uploadResource(
      params.fileBuffer,
      params.fileName,
      fields
    );
    if (res.code === 401) {
      return ResultUtil.fail<UploadResourceResultModel>(401, res.message || '登录已过期');
    }
    if ((res.code !== 200 && res.code !== 201) || !res.data) {
      return ResultUtil.fail<UploadResourceResultModel>(
        res.code,
        res.message || '资料上传失败'
      );
    }
    Logger.info(TAG, `资料上传成功: ${res.data.id}`);
    return ResultUtil.success(new UploadResourceResultModel(
      res.data.id,
      res.data.title,
      res.data.status,
      res.data.created_at || '',
      res.message || '资料提交成功'
    ));
  }
}

export const sharedResourceRepository: SharedResourceRepository = new SharedResourceRepository();
