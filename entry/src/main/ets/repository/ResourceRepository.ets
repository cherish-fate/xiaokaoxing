import { apiService, ApiResponse, ResourceListResponse, ResourceItem } from '../api/ApiService';
import { ResourceModel } from '../model/ResourceModel';
import { ResultUtil, AsyncResult } from '../utils/ResultUtil';

export class ResourceRepository {
  async fetchRecommendedResources(limit: number = 4): Promise<AsyncResult<ResourceModel[]>> {
    const res: ApiResponse<ResourceListResponse> = await apiService.fetchRecommendedResources(limit);
    if (res.code === 401) {
      return ResultUtil.fail<ResourceModel[]>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<ResourceModel[]>(res.code, res.message || '获取推荐资源失败');
    }
    const list = (res.data.list || []).map((item: ResourceItem) =>
      new ResourceModel(item.id, item.title, item.type_tag, item.description, item.file_url || '')
    );
    return ResultUtil.success(list);
  }
}

export const resourceRepository: ResourceRepository = new ResourceRepository();
