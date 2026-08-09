import {
  apiService,
  ApiResponse,
  PrepHomeResponse,
  RecommendationItem,
  ResourceItem,
  ResourceListResponse,
  FavoriteRequest,
  FavoriteResponse
} from '../api/ApiService';
import { PrepPageModel, RecommendationItemModel, PrepResourceItemModel } from '../model/PrepModel';
import { ResultUtil, AsyncResult } from '../utils/ResultUtil';
import { Logger } from '../utils/Logger';
import { DateUtil } from '../utils/DateUtil';

const TAG = 'PrepRepository';

export interface ResourceListResult {
  list: PrepResourceItemModel[];
  total: number;
}

export class PrepRepository {
  private mapResource(item: ResourceItem): PrepResourceItemModel {
    return new PrepResourceItemModel(
      item.id,
      item.title || '',
      item.category || '',
      item.type_tag || '',
      !!item.is_hot,
      item.author || '',
      item.created_at ? DateUtil.toShortDate(item.created_at) : '',
      item.view_count || 0,
      !!item.is_favorited,
      item.file_url || ''
    );
  }

  private mapRecommendation(item: RecommendationItem): RecommendationItemModel {
    return new RecommendationItemModel(
      item.id,
      item.emoji || '📌',
      item.description || '',
      item.suggestion || '',
      item.target_type || '',
      item.target_id || 0
    );
  }

  async loadPrepHome(
    category: string = '真题试卷',
    limit: number = 10,
    offset: number = 0
  ): Promise<AsyncResult<PrepPageModel>> {
    const res: ApiResponse<PrepHomeResponse> = await apiService.fetchPrepHome(category, limit, offset);
    if (res.code === 401) {
      return ResultUtil.fail<PrepPageModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<PrepPageModel>(res.code, res.message || '备考中心数据加载失败');
    }
    const recommendations = (res.data.recommendations || []).map(r => this.mapRecommendation(r));
    const resources = (res.data.resources?.list || []).map(r => this.mapResource(r));
    const total = res.data.resources?.total || resources.length;
    const model = new PrepPageModel(recommendations, resources, total);
    Logger.info(TAG, '备考中心数据加载成功');
    return ResultUtil.success(model);
  }

  async loadResources(
    category: string,
    limit: number = 10,
    offset: number = 0
  ): Promise<AsyncResult<ResourceListResult>> {
    const res: ApiResponse<ResourceListResponse> = await apiService.fetchResources(category, limit, offset);
    if (res.code === 401) {
      return ResultUtil.fail<ResourceListResult>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<ResourceListResult>(
        res.code, res.message || '资源加载失败'
      );
    }
    const list: PrepResourceItemModel[] = (res.data.list || []).map(r => this.mapResource(r));
    const total: number = res.data.total || list.length;
    const result: ResourceListResult = {
      list: list,
      total: total
    };

    return ResultUtil.success(result);
  }

  async toggleFavorite(
    resourceId: number,
    isFavorited: boolean
  ): Promise<AsyncResult<boolean>> {
    const req: FavoriteRequest = { is_favorited: isFavorited };
    const res: ApiResponse<FavoriteResponse> = await apiService.toggleFavorite(resourceId, req);
    if (res.code === 401) {
      return ResultUtil.fail<boolean>(401, res.message || '登录已过期');
    }
    if (res.code === 404) {
      return ResultUtil.fail<boolean>(404, res.message || '资源不存在');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<boolean>(res.code, res.message || '收藏失败');
    }
    Logger.info(TAG, `收藏操作成功: ${res.data.is_favorited}`);
    return ResultUtil.success(res.data.is_favorited);
  }
}

export const prepRepository: PrepRepository = new PrepRepository();
