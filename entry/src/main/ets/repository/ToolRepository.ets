import { apiService, ApiResponse, ToolboxHomeResponse } from '../api/ApiService';
import { ToolPageModel } from '../model/ToolModel';
import { ResultUtil, AsyncResult } from '../utils/ResultUtil';
import { Logger } from '../utils/Logger';

const TAG = 'ToolRepository';

export class ToolRepository {
  async loadToolboxHome(): Promise<AsyncResult<ToolPageModel>> {
    const res: ApiResponse<ToolboxHomeResponse> = await apiService.fetchToolboxHome();
    if (res.code === 401) {
      return ResultUtil.fail<ToolPageModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<ToolPageModel>(res.code, res.message || '工具箱数据加载失败');
    }
    try {
      const data: ToolPageModel = ToolPageModel.fromApi(res.data);
      Logger.info(TAG, '工具箱主页加载成功');
      return ResultUtil.success(data);
    } catch (e) {
      Logger.error(TAG, '工具箱数据转换失败', e as Error);
      return ResultUtil.fail<ToolPageModel>(500, '数据解析失败');
    }
  }
}

export const toolRepository: ToolRepository = new ToolRepository();
