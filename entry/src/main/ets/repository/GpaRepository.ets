import {
  apiService,
  ApiResponse,
  SemesterListResponse,
  CreateSemesterRequest,
  SemesterItem,
  CourseListResponse,
  CourseItem,
  SaveCourseRequest,
  SaveCourseResponse,
  GpaCalculateResponse
} from '../api/ApiService';
import {
  SemesterModel,
  CourseModel,
  GpaCalculateModel
} from '../model/GpaModel';
import { ResultUtil, AsyncResult } from '../utils/ResultUtil';
import { Logger } from '../utils/Logger';

const TAG: string = 'GpaRepository';

interface GpaCourseListResult {
  semesterName: string;
  courses: CourseModel[];
}

export class GpaRepository {
  async loadSemesters(): Promise<AsyncResult<SemesterModel[]>> {
    const res: ApiResponse<SemesterListResponse> = await apiService.fetchSemesters();
    if (res.code === 401) {
      return ResultUtil.fail<SemesterModel[]>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<SemesterModel[]>(res.code, res.message || '获取学期列表失败');
    }
    try {
      const list: SemesterModel[] = (res.data.list || []).map(s => SemesterModel.fromApi(s));
      Logger.info(TAG, '学期列表加载成功');
      return ResultUtil.success(list);
    } catch (e) {
      Logger.error(TAG, '学期列表数据转换失败', e as Error);
      return ResultUtil.fail<SemesterModel[]>(500, '数据解析失败');
    }
  }

  async createSemester(name: string, year: number): Promise<AsyncResult<SemesterModel>> {
    const req: CreateSemesterRequest = { name, year };
    const res: ApiResponse<SemesterItem> = await apiService.createSemester(req);
    if (res.code === 401) {
      return ResultUtil.fail<SemesterModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 201 || !res.data) {
      return ResultUtil.fail<SemesterModel>(res.code, res.message || '创建学期失败');
    }
    try {
      const model: SemesterModel = SemesterModel.fromApi(res.data);
      Logger.info(TAG, '学期创建成功');
      return ResultUtil.success(model);
    } catch (e) {
      Logger.error(TAG, '学期数据转换失败', e as Error);
      return ResultUtil.fail<SemesterModel>(500, '数据解析失败');
    }
  }

  async deleteSemester(id: number): Promise<AsyncResult<null>> {
    const res: ApiResponse<null> = await apiService.deleteSemester(id);
    if (res.code === 401) {
      return ResultUtil.fail<null>(401, res.message || '登录已过期');
    }
    if (res.code !== 200) {
      return ResultUtil.fail<null>(res.code, res.message || '删除学期失败');
    }
    Logger.info(TAG, '学期删除成功');
    return ResultUtil.success(null);
  }

  async loadCourses(semesterId: number): Promise<AsyncResult<GpaCourseListResult>> {
    const res: ApiResponse<CourseListResponse> = await apiService.fetchCourses(semesterId);
    if (res.code === 401) {
      return ResultUtil.fail<GpaCourseListResult>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<GpaCourseListResult>(res.code, res.message || '获取课程列表失败');
    }
    try {
      const list: CourseModel[] = (res.data.list || []).map(c => CourseModel.fromApi(c));
      const result: GpaCourseListResult = {
        semesterName: res.data.semester || '',
        courses: list
      };
      Logger.info(TAG, '课程列表加载成功');
      return ResultUtil.success<GpaCourseListResult>(result);
    } catch (e) {
      Logger.error(TAG, '课程列表数据转换失败', e as Error);
      return ResultUtil.fail<GpaCourseListResult>(500, '数据解析失败');
    }
  }

  async saveCourse(req: SaveCourseRequest): Promise<AsyncResult<SaveCourseResponse>> {
    const res: ApiResponse<SaveCourseResponse> = await apiService.saveCourse(req);
    if (res.code === 401) {
      return ResultUtil.fail<SaveCourseResponse>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<SaveCourseResponse>(res.code, res.message || '保存课程失败');
    }
    Logger.info(TAG, '课程保存成功');
    return ResultUtil.success(res.data);
  }

  async deleteCourse(id: number): Promise<AsyncResult<null>> {
    const res: ApiResponse<null> = await apiService.deleteCourse(id);
    if (res.code === 401) {
      return ResultUtil.fail<null>(401, res.message || '登录已过期');
    }
    if (res.code !== 200) {
      return ResultUtil.fail<null>(res.code, res.message || '删除课程失败');
    }
    Logger.info(TAG, '课程删除成功');
    return ResultUtil.success(null);
  }

  async calculateGpa(algorithm: string = 'standard'): Promise<AsyncResult<GpaCalculateModel>> {
    const res: ApiResponse<GpaCalculateResponse> = await apiService.calculateGpa(algorithm);
    if (res.code === 401) {
      return ResultUtil.fail<GpaCalculateModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<GpaCalculateModel>(res.code, res.message || '绩点计算失败');
    }
    try {
      const model: GpaCalculateModel = GpaCalculateModel.fromApi(res.data);
      Logger.info(TAG, '绩点计算成功');
      return ResultUtil.success(model);
    } catch (e) {
      Logger.error(TAG, '绩点数据转换失败', e as Error);
      return ResultUtil.fail<GpaCalculateModel>(500, '数据解析失败');
    }
  }
}

export const gpaRepository: GpaRepository = new GpaRepository();
