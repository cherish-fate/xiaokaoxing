import {
  apiService,
  ApiResponse,
  DocumentListResponse,
  DocumentItem,
  UpdateDocOfflineResponse,
  DocumentFromResourceResponse
} from '../api/ApiService';
import { DocumentItemModel, DocumentListModel } from '../model/DocumentModel';
import { ResultUtil, AsyncResult } from '../utils/ResultUtil';
import { Logger } from '../utils/Logger';

const TAG: string = 'DocumentRepository';

interface DocOfflineResult {
  id: number;
  isOffline: boolean;
}

interface DocFromResourceResult {
  documentId: number;
  alreadyExists: boolean;
}

export class DocumentRepository {
  async loadDocuments(
    category: string | null = null,
    limit: number = 20,
    offset: number = 0
  ): Promise<AsyncResult<DocumentListModel>> {
    const categoryParam: string | null = (category === '全部') ? null : category;
    const res: ApiResponse<DocumentListResponse> = await apiService.fetchDocuments(categoryParam, limit, offset);
    if (res.code === 401) {
      return ResultUtil.fail<DocumentListModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<DocumentListModel>(res.code, res.message || '获取文档列表失败');
    }
    try {
      const list: DocumentItemModel[] = (res.data.list || []).map(d => DocumentItemModel.fromApi(d));
      const total: number = res.data.total || 0;
      Logger.info(TAG, `文档列表加载成功，共${total}条，当前加载${list.length}条`);
      return ResultUtil.success(DocumentListModel.fromTotalAndList(total, list));
    } catch (e) {
      Logger.error(TAG, '文档列表数据转换失败', e as Error);
      return ResultUtil.fail<DocumentListModel>(500, '数据解析失败');
    }
  }

  async updateOffline(id: number, isOffline: boolean): Promise<AsyncResult<DocOfflineResult>> {
    const res: ApiResponse<UpdateDocOfflineResponse> = await apiService.updateDocOffline(id, isOffline);
    if (res.code === 401) {
      return ResultUtil.fail<DocOfflineResult>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<DocOfflineResult>(res.code, res.message || '更新离线状态失败');
    }
    Logger.info(TAG, `文档${id}离线状态更新为${isOffline}`);
    const result: DocOfflineResult = {
      id: res.data.id || id,
      isOffline: !!res.data.is_offline
    };
    return ResultUtil.success(result);
  }

  async deleteDocument(id: number): Promise<AsyncResult<null>> {
    const res: ApiResponse<null> = await apiService.deleteDocument(id);
    if (res.code === 401) {
      return ResultUtil.fail<null>(401, res.message || '登录已过期');
    }
    if (res.code !== 200) {
      return ResultUtil.fail<null>(res.code, res.message || '删除文档失败');
    }
    Logger.info(TAG, `文档${id}删除成功`);
    return ResultUtil.success(null);
  }

  async createFromResource(resourceId: number): Promise<AsyncResult<DocFromResourceResult>> {
    const res: ApiResponse<DocumentFromResourceResponse> =
      await apiService.createDocumentFromResource(resourceId);
    if (res.code === 401) {
      return ResultUtil.fail<DocFromResourceResult>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<DocFromResourceResult>(res.code, res.message || '同步到文档库失败');
    }
    const result: DocFromResourceResult = {
      documentId: res.data.document_id || 0,
      alreadyExists: !!res.data.already_exists
    };
    Logger.info(TAG, `资源${resourceId}同步到文档库成功，documentId=${result.documentId}，alreadyExists=${result.alreadyExists}`);
    return ResultUtil.success(result);
  }

  // 取消收藏时，按 resource_id 删除文档库中对应文档
  async deleteFromResource(resourceId: number): Promise<AsyncResult<null>> {
    const res: ApiResponse<null> = await apiService.deleteDocumentFromResource(resourceId);
    if (res.code === 401) {
      return ResultUtil.fail<null>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 && res.code !== 404) {
      return ResultUtil.fail<null>(res.code, res.message || '从文档库删除失败');
    }
    Logger.info(TAG, `资源${resourceId}对应文档已从文档库删除`);
    return ResultUtil.success(null);
  }
}

export const documentRepository: DocumentRepository = new DocumentRepository();
