import http from '@ohos.net.http';
import { Logger } from '../utils/Logger';
import { StorageUtil } from '../utils/StorageUtil';

const TAG = 'ApiService';
const BASE_URL: string = 'http://10.0.2.2:3000';

export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T | null;
}

export interface Major {
  id: number;
  name: string;
}

export interface RegisterRequest {
  nickname: string;
  email: string;
  password: string;
  school_name: string;
  major_id: number;
}

export interface RegisterData {
  id: number;
  nickname: string;
  email: string;
  school_name: string;
  major_id: number;
  avatar_url: string | null;
  created_at: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface UserInfo {
  id: number;
  email: string;
  nickname: string;
  school_name: string;
  major_id: number;
  avatar_url: string | null;
  created_at: string;
  updated_at: string;
}

export interface AuthData {
  id: number;
  nickname: string;
  email: string;
  school_name: string;
  major_id: number;
  avatar_url: string | null;
  created_at: string;
  updated_at: string;
  token: string;
}

export interface ExamCountdown {
  has_exam: boolean;
  exam_name: string;
  exam_date: string;
  start_time: string;
  end_time: string;
  countdown_days: number;
  countdown_text: string;
}

export interface TodayProgress {
  completed: number;
  total: number;
  progress_percentage: number;
}

export interface RecentExamItem {
  id: number;
  name: string;
  exam_date: string;
  start_time: string;
  end_time: string;
  location: string;
  days_remaining: number;
  days_text: string;
}

export interface ExamItem {
  id: number;
  name: string;
  exam_date: string;
  start_time: string;
  end_time: string;
  location: string;
  is_completed: boolean;
  days_remaining: number;
  days_text: string;
  status: string;
}

export interface TaskItem {
  id: number;
  task_name: string;
  plan_date: string;
  is_completed: boolean;
}

export interface ResourceItem {
  id: number;
  title: string;
  type_tag: string;
  description: string;
  file_url?: string;
  category?: string;
  is_hot?: boolean;
  author?: string;
  created_at?: string;
  view_count?: number;
  is_favorited?: boolean;
}

export interface RecommendationItem {
  id: number;
  emoji: string;
  description: string;
  suggestion: string;
  target_type: string;
  target_id: number;
}

export interface ResourceListData {
  total: number;
  list: ResourceItem[];
  keyword?: string;
}

export interface PrepHomeResponse {
  recommendations: RecommendationItem[];
  resources: ResourceListData;
}

export interface FavoriteRequest {
  is_favorited: boolean;
}

export interface FavoriteResponse {
  resource_id: number;
  is_favorited: boolean;
}

export interface AiChatRequest {
  message: string;
  conversation_id?: string;
  attachment_url?: string;
}

export interface AiUploadResponse {
  file_url: string;
  file_name: string;
  file_size: number;
}

interface SseChunkMessage {
  type: string;
  content?: string;
  conversation_id?: string;
  full_content?: string;
  message?: string;
}

interface userInterface {
  id: number;
  nickname: string;
  avatar_url: string | null;
}

export interface HomeAggregate {
  user: userInterface;
  exam_countdown: ExamCountdown;
  today_progress: TodayProgress;
  recent_exams: RecentExamItem[];
  today_tasks: TaskItem[];
  recommended_resources: ResourceItem[];
}

export interface ExamListResponse {
  total: number;
  list: ExamItem[];
}

export interface TodayTaskResponse {
  has_tasks: boolean;
  total: number;
  completed: number;
  list: TaskItem[];
  empty_hint?: string;
}

export interface ResourceListResponse {
  total: number;
  list: ResourceItem[];
  keyword?: string;
  empty_hint?: string;
}

export interface CreateExamRequest {
  name: string;
  exam_date: string;
  start_time: string;
  end_time?: string;
  location?: string;
  is_completed?: boolean;
}

export interface UpdateExamRequest {
  name?: string;
  exam_date?: string;
  start_time?: string;
  end_time?: string;
  location?: string;
  is_completed?: boolean;
}

export interface CreateTaskRequest {
  task_name: string;
  plan_date?: string;
  is_completed?: boolean;
}

export interface UpdateTaskRequest {
  task_name?: string;
  plan_date?: string;
  is_completed?: boolean;
}

// ================ 社区模块接口 ================

// 1. 社区主页
export interface CheckinStats {
  total_days: number;
  continuous_days: number;
  rank: number;
}
export interface HotVote {
  id: number;
  subject: string;
  title: string;
  vote_count: number;
  confidence: number;
  stars: number;
}
export interface HotTeam {
  id: number;
  name: string;
  subject: string;
  member_count: number;
  max_members: number;
  checkin_rate: number;
  total_checkins: number;
  online_count: number;
  is_creator: boolean;
  join_status: string | null;
}
export interface CommunityResource {
  id: number;
  title: string;
  author: string;
  created_at: string;
  status: string;
}
export interface CommunityHomeResponse {
  checkin_stats: CheckinStats;
  hot_votes: HotVote[];
  hot_teams: HotTeam[];
  latest_resources: CommunityResource[];
}

// 2. 打卡模块
export interface CheckinRecord {
  id: number;
  subjects: string[];
  duration: string;
  note: string;
  tags: string[];
}
export interface TodayCheckinResponse {
  has_checked_in: boolean;
  continuous_days: number;
  total_days: number;
  rank: number;
  checkin_record?: CheckinRecord;
}
export interface CheckinSubmitRequest {
  subjects?: string[];
  duration?: string;
  note?: string;
  tags?: string[];
}
export interface CheckinSubmitResponse {
  id: number;
  checkin_date: string;
  continuous_days: number;
  total_days: number;
  earned_points: number;
}
export interface CalendarDay {
  date: string;
  day: number;
  is_checked: boolean;
  is_today: boolean;
}
export interface CalendarResponse {
  year: number;
  month: number;
  days: CalendarDay[];
}
export interface RankUser {
  rank: number;
  user_id: number;
  nickname: string;
  avatar_url: string | null;
  continuous_days: number;
  total_days: number;
}
export interface RankingResponse {
  list: RankUser[];
  my_rank: RankUser;
}

// 3. 小队模块
export interface TeamItem {
  id: number;
  name: string;
  subject: string;
  description: string | null;
  member_count: number;
  max_members: number;
  checkin_rate: number;
  total_checkins: number;
  online_count: number;
  is_creator: boolean;
  join_status: string | null;
  pending_requests?: number;
  resource_count?: number;
}
export interface TeamListResponse {
  my_teams: TeamItem[];
  recommended_teams: TeamItem[];
}
export interface TeamMember {
  user_id: number;
  nickname: string;
  avatar_url: string | null;
  role: string;
  joined_at: string;
}
export interface TeamDetailResponse {
  id: number;
  name: string;
  subject: string;
  description: string | null;
  creator_id: number;
  member_count: number;
  max_members: number;
  checkin_rate: number;
  total_checkins: number;
  need_approval: boolean;
  is_creator: boolean;
  is_member: boolean;
  members: TeamMember[];
}
export interface CreateTeamRequest {
  name: string;
  subject: string;
  description?: string;
  need_approval?: boolean;
}
export interface CreateTeamResponse {
  id: number;
  name: string;
  subject: string;
  description: string | null;
  member_count: number;
  max_members: number;
  need_approval: boolean;
  created_at: string;
}
export interface JoinResponse {
  team_id: number;
  status: string;
  applied_at?: string;
}
export interface JoinApplication {
  application_id: number;
  user_id: number;
  nickname: string;
  avatar_url: string | null;
  applied_at: string;
}
export interface ApplicationsResponse {
  pending: JoinApplication[];
  total: number;
}
export interface ApplicationProcessRequest {
  action: string; // 'approve' | 'reject'
}
export interface ApplicationProcessResponse {
  application_id: number;
  status: string;
}

// 4. 考点投票模块
export interface VoteItem {
  id: number;
  subject: string;
  title: string;
  description: string | null;
  vote_count: number;
  confidence: number;
  stars: number;
  has_voted: boolean;
}
export interface VoteListResponse {
  list: VoteItem[];
}
export interface SubmitVoteRequest {
  subject: string;
  title: string;
  description?: string;
}
export interface SubmitVoteResponse {
  id: number;
  subject: string;
  title: string;
  status: string;
  created_at: string;
}
export interface VoteResultResponse {
  vote_id: number;
  vote_count: number;
  confidence: number;
}
export interface MyVoteRecord {
  vote_id: number;
  subject: string;
  title: string;
  vote_count: number;
  confidence: number;
  voted_at: string;
  my_choice?: string;
}
export interface MyVoteListResponse {
  list: MyVoteRecord[];
}
export interface MySubmissionItem {
  id: number;
  subject: string;
  title: string;
  description: string | null;
  status: string;
  created_at: string;
}
export interface MySubmissionsResponse {
  list: MySubmissionItem[];
}

export interface PendingSubmission {
  id: number;
  subject: string;
  title: string;
  description: string | null;
  status: string;
  created_at: string;
  author_name: string;
  author_avatar: string | null;
}
export interface PendingSubmissionsResponse {
  list: PendingSubmission[];
}

// 5. 上传资料模块
export interface MyUploadItem {
  id: number;
  title: string;
  category: string;
  type: string;
  status: string;
  created_at: string;
  view_count: number;
  reject_reason?: string;
}
export interface MyUploadListResponse {
  list: MyUploadItem[];
}
export interface UploadResourceResponse {
  id: number;
  title: string;
  status: string;
  created_at: string;
}

// ================ 工具模块接口 ================

// 1. 工具箱主页聚合
export interface DailyQuestionHome {
  has_answered: boolean;
  question: string;
  subject: string;
  date: string;
}
export interface NoteTagCount {
  name: string;
  count: number;
}
export interface NotesHomeSummary {
  count: number;
  tags: NoteTagCount[];
}
export interface GpaHomeSummary {
  current: number;
  trend: number;
  semester: string;
}
export interface DocumentsHomeSummary {
  total: number;
  categories: Record<string, number>;
}
export interface BookmarksHomeSummary {
  total: number;
}
export interface ToolboxHomeResponse {
  daily_question: DailyQuestionHome;
  notes: NotesHomeSummary;
  gpa: GpaHomeSummary;
  documents: DocumentsHomeSummary;
  bookmarks: BookmarksHomeSummary;
}

// 2. 每日一问
export interface DailyAnsweredRecord {
  selected: string;
  is_correct: boolean;
  explanation: string;
}
export interface DailyQuestionToday {
  id: number;
  subject: string;
  question: string;
  options: string[];
  difficulty: number;
  date: string;
  has_answered: boolean;
  record?: DailyAnsweredRecord;
}
export interface SubmitDailyAnswerRequest {
  question_id: number;
  selected: string;
}
export interface SubmitDailyAnswerData {
  is_correct: boolean;
  correct_answer?: string;
  explanation: string;
  earned_points?: number;
  wrong_book_added?: boolean;
}
export interface AnswerHistoryItem {
  id: number;
  question_id: number;
  subject: string;
  selected: string;
  is_correct: boolean;
  answered_at: string;
}
export interface AnswerCalendarDay {
  date: string;
  has_answered: boolean;
}
export interface DailyQuestionHistoryResponse {
  list: AnswerHistoryItem[];
  calendar: AnswerCalendarDay[];
}

// 3. 学习笔记
export interface NoteListItem {
  id: number;
  title: string;
  content_preview: string;
  tags: string[];
  is_pinned: boolean;
  source_type: string;
  updated_at: string;
}
export interface NoteListResponse {
  total: number;
  list: NoteListItem[];
}
export interface CreateNoteRequest {
  title: string;
  content?: string;
  tags?: string[];
}
export interface NoteDetailResponse {
  id: number;
  title: string;
  content: string;
  tags: string[];
  is_pinned: boolean;
  source_type: string;
  source_id?: number;
  created_at: string;
  updated_at: string;
}
export interface UpdateNoteRequest {
  title?: string;
  content?: string;
  tags?: string[];
}
export interface UpdateNoteResponse {
  id: number;
  updated_at: string;
}
export interface ExcerptNoteRequest {
  source_type: string;
  source_id: number;
  title: string;
  content: string;
  tags?: string[];
}
export interface TogglePinRequest {
  is_pinned: boolean;
}
export interface TogglePinResponse {
  id: number;
  is_pinned: boolean;
}

// 4. 绩点计算器
export interface SemesterItem {
  id: number;
  name: string;
  year: number;
  course_count: number;
}
export interface SemesterListResponse {
  list: SemesterItem[];
}
export interface CreateSemesterRequest {
  name: string;
  year: number;
}
export interface CourseItem {
  id: number;
  name: string;
  credit: number;
  score?: number;
  grade?: string;
  type: string;
  gpa: number;
}
export interface CourseListResponse {
  semester: string;
  list: CourseItem[];
}
export interface SaveCourseRequest {
  id?: number;
  semester_id: number;
  name: string;
  credit: number;
  score?: number;
  grade?: string;
  type: string;
}
export interface SaveCourseResponse {
  id: number;
  name: string;
  gpa: number;
}
export interface GpaTarget {
  value: number;
  gap: number;
  status: string;
}
export interface GpaWarning {
  course_name: string;
  score: number;
  credit: number;
  message: string;
}
export interface GpaCalculateResponse {
  algorithm: string;
  current_gpa: number;
  total_credits: number;
  targets: Record<string, GpaTarget>;
  warnings: GpaWarning[];
  failed_courses: number;
  failed_credits: number;
}

// 5. 个人文档库
export interface DocumentItem {
  id: number;
  name: string;
  file_url: string;
  file_size: number;
  file_type: string;
  category: string;
  is_offline: boolean;
  last_opened_at?: string;
}
export interface DocumentListResponse {
  total: number;
  list: DocumentItem[];
}
export interface StorageStatusResponse {
  used: number;
  used_display: string;
  total: number;
  total_display: string;
  percentage: number;
  is_warning: boolean;
}
export interface UpdateDocOfflineRequest {
  is_offline: boolean;
}
export interface UpdateDocOfflineResponse {
  id: number;
  is_offline: boolean;
}

// 6. 精选书签
export interface BookmarkItem {
  id: number;
  quote: string;
  source_title: string;
  source_url?: string;
  source_type: string;
  source_id?: number;
  anchor?: string;
  note?: string;
  color: string;
  created_at: string;
}
export interface BookmarkListResponse {
  total: number;
  list: BookmarkItem[];
}
export interface CreateBookmarkRequest {
  quote: string;
  source_title: string;
  source_url?: string;
  source_type: string;
  source_id?: number;
  anchor?: string;
  note?: string;
  color?: string;
}
export interface CreateBookmarkResponse {
  id: number;
  color: string;
  created_at: string;
}
export interface UpdateBookmarkRequest {
  note?: string;
  color?: string;
}
export interface UpdateBookmarkResponse {
  id: number;
  note?: string;
  color: string;
  updated_at: string;
}

// ============== 我的页模块接口 ==============

// 1. 用户信息
export interface UserMeInfo {
  id: number;
  nickname: string;
  email: string;
  school_name: string;
  major_id: number;
  major_name: string;
  avatar_url: string | null;
  created_at: string;
}

export interface UpdateUserMeRequest {
  nickname?: string;
  school_name?: string;
  major_id?: number;
  avatar_url?: string | null;
  old_password?: string;
  new_password?: string;
  confirm_new_password?: string;
}

// 2. 聚合统计
export interface CheckinStatsSummary {
  continuous_days: number;
  total_days: number;
  rank: number;
}
export interface LearningStatsSummary {
  notes_count: number;
  bookmarks_count: number;
  documents_count: number;
  current_gpa: number;
  daily_question_count: number;
  exam_subjects_count: number;
}
export interface MyContentCounts {
  uploads_count: number;
  votes_count: number;
  submissions_count: number;
  teams_count: number;
}
export interface UserStatsAggregate {
  checkin: CheckinStatsSummary;
  learning: LearningStatsSummary;
  my_content: MyContentCounts;
}

// 3. 学习数据概览（独立接口）
export interface LearningStatsResponse {
  notes_count: number;
  bookmarks_count: number;
  documents_count: number;
  current_gpa: number;
  daily_question_count: number;
  exam_subjects_count: number;
}

// 4. 我的小队
export interface MyTeamItem {
  id: number;
  name: string;
  subject: string;
  role: string;
  member_count: number;
  max_members: number;
  checkin_rate: number;
}
export interface MyTeamsListResponse {
  list: MyTeamItem[];
}

// 5. 通知设置
export interface NotificationSettingsResponse {
  exam_reminder: boolean;
  checkin_reminder: boolean;
}
export interface UpdateNotificationSettingsRequest {
  exam_reminder?: boolean;
  checkin_reminder?: boolean;
}

// 6. 关于信息
export interface AboutInfoResponse {
  version: string;
  app_name: string;
  description: string;
  team?: string;
  website?: string;
  support_email?: string;
  privacy_url?: string;
  terms_url?: string;
  copyright?: string;
}

// 7. 上传记录（已有接口但补充类型）
// MyUploadItem / MyUploadListResponse 已在上方社区模块定义

class ApiService {
  private httpRequest: http.HttpRequest | null = null;

  getBaseUrl(): string {
    return BASE_URL;
  }

  async getToken(): Promise<string> {
    return StorageUtil.getString('token', '');
  }

  async saveToken(token: string): Promise<void> {
    await StorageUtil.put('token', token);
  }

  private async request<T>(
    path: string,
    method: http.RequestMethod,
    body: object | null = null,
    needAuth: boolean = false,
    query: Record<string, string | number> | null = null
  ): Promise<ApiResponse<T>> {
    if (!this.httpRequest) {
      this.httpRequest = http.createHttp();
    }

    let url: string = `${BASE_URL}${path}`;
    if (query && Object.keys(query).length > 0) {
      const qs = Object.keys(query)
        .map(k => `${encodeURIComponent(k)}=${encodeURIComponent(String(query[k]))}`)
        .join('&');
      url = `${url}?${qs}`;
    }

    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };

    if (needAuth) {
      const token = await this.getToken();
      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
      }
    }

    const requestOptions: http.HttpRequestOptions = {
      method: method,
      header: headers,
      connectTimeout: 10000,
      readTimeout: 10000
    };

    if (body) {
      requestOptions.extraData = JSON.stringify(body);
    }

    try {
      const response = await this.httpRequest.request(url, requestOptions);
      const result: ApiResponse<T> = JSON.parse(response.result as string);
      return result;
    } catch (error) {
      Logger.error(TAG, `HTTP请求失败: ${url}`, error as Error);
      return {
        code: 500,
        message: '网络请求失败，请检查网络连接',
        data: null
      };
    }
  }

  async getMajors(): Promise<ApiResponse<Major[]>> {
    return this.request<Major[]>('/api/majors', http.RequestMethod.GET);
  }

  async register(req: RegisterRequest): Promise<ApiResponse<RegisterData>> {
    return this.request<RegisterData>('/api/users/register', http.RequestMethod.POST, req);
  }

  async login(req: LoginRequest): Promise<ApiResponse<AuthData>> {
    return this.request<AuthData>('/api/users/login', http.RequestMethod.POST, req);
  }

  async fetchHome(): Promise<ApiResponse<HomeAggregate>> {
    return this.request<HomeAggregate>('/api/home', http.RequestMethod.GET, null, true);
  }

  async fetchExams(
    limit: number = 3,
    status: string = ''
  ): Promise<ApiResponse<ExamListResponse>> {
    const query: Record<string, string | number> = {};
    query['limit'] = limit;
    if (status) {
      query['status'] = status;
    }
    return this.request<ExamListResponse>('/api/exams', http.RequestMethod.GET, null, true, query);
  }

  async createExam(req: CreateExamRequest): Promise<ApiResponse<ExamItem>> {
    return this.request<ExamItem>('/api/exams', http.RequestMethod.POST, req, true);
  }

  async updateExam(id: number, req: UpdateExamRequest): Promise<ApiResponse<ExamItem>> {
    return this.request<ExamItem>(`/api/exams/${id}`, http.RequestMethod.PUT, req, true);
  }

  async deleteExam(id: number): Promise<ApiResponse<null>> {
    return this.request<null>(`/api/exams/${id}`, http.RequestMethod.DELETE, null, true);
  }

  async fetchTodayTasks(): Promise<ApiResponse<TodayTaskResponse>> {
    return this.request<TodayTaskResponse>('/api/tasks/today', http.RequestMethod.GET, null, true);
  }

  async createTask(req: CreateTaskRequest): Promise<ApiResponse<TaskItem>> {
    return this.request<TaskItem>('/api/tasks', http.RequestMethod.POST, req, true);
  }

  async updateTask(id: number, req: UpdateTaskRequest): Promise<ApiResponse<TaskItem>> {
    return this.request<TaskItem>(`/api/tasks/${id}`, http.RequestMethod.PUT, req, true);
  }

  async deleteTask(id: number): Promise<ApiResponse<null>> {
    return this.request<null>(`/api/tasks/${id}`, http.RequestMethod.DELETE, null, true);
  }

  async fetchRecommendedResources(limit: number = 4): Promise<ApiResponse<ResourceListResponse>> {
    return this.request<ResourceListResponse>(
      '/api/resources/recommended',
      http.RequestMethod.GET,
      null,
      true,
    );
  }

  async fetchPrepHome(
    category: string = '真题试卷',
    limit: number = 10,
    offset: number = 0
  ): Promise<ApiResponse<PrepHomeResponse>> {
    const query: Record<string, string | number> = {};
    query['category'] = category;
    query['limit'] = limit;
    query['offset'] = offset;
    return this.request<PrepHomeResponse>('/api/prep/home', http.RequestMethod.GET, null, true, query);
  }

  async fetchResources(
    category: string = '',
    limit: number = 10,
    offset: number = 0
  ): Promise<ApiResponse<ResourceListResponse>> {
    const query: Record<string, string | number> = {};
    query['limit'] = limit;
    query['offset'] = offset;
    if (category) {
      query['category'] = category;
    }
    return this.request<ResourceListResponse>('/api/resources', http.RequestMethod.GET, null, true, query);
  }

  async searchResources(
    keyword: string,
    limit: number = 10,
    offset: number = 0
  ): Promise<ApiResponse<ResourceListResponse>> {
    const query: Record<string, string | number> = {};
    query['keyword'] = keyword;
    query['limit'] = limit;
    query['offset'] = offset;
    return this.request<ResourceListResponse>('/api/resources/search', http.RequestMethod.GET, null, true, query);
  }

  async toggleFavorite(id: number, req: FavoriteRequest): Promise<ApiResponse<FavoriteResponse>> {
    return this.request<FavoriteResponse>(
      `/api/resources/${id}/favorite`,
      http.RequestMethod.POST,
      req,
      true
    );
  }

  async uploadAiFile(formData: ArrayBuffer, fileName: string): Promise<ApiResponse<AiUploadResponse>> {
    return this.requestMultipart<AiUploadResponse>(
      '/api/ai/upload',
      formData,
      fileName
    );
  }

  private async requestMultipart<T>(
    path: string,
    fileBuffer: ArrayBuffer,
    fileName: string
  ): Promise<ApiResponse<T>> {
    if (!this.httpRequest) {
      this.httpRequest = http.createHttp();
    }
    const url = `${BASE_URL}${path}`;
    const token = await this.getToken();
    const boundary = '---xiaokaoxing-boundary';
    const headerStr = '--' + boundary + '\r\nContent-Disposition: form-data; name="file"; filename="' + fileName + '"\r\nContent-Type: application/octet-stream\r\n\r\n';
    const footerStr = '\r\n--' + boundary + '--\r\n';
    const headerBytes = new Uint8Array(headerStr.length);
    for (let i = 0; i < headerStr.length; i++) headerBytes[i] = headerStr.charCodeAt(i);
    const footerBytes = new Uint8Array(footerStr.length);
    for (let i = 0; i < footerStr.length; i++) footerBytes[i] = footerStr.charCodeAt(i);
    const totalLen = headerBytes.length + fileBuffer.byteLength + footerBytes.length;
    const combined = new Uint8Array(totalLen);
    combined.set(headerBytes, 0);
    combined.set(new Uint8Array(fileBuffer), headerBytes.length);
    combined.set(footerBytes, headerBytes.length + fileBuffer.byteLength);
    const headers: Record<string, string> = {};
    headers['Content-Type'] = 'multipart/form-data; boundary=' + boundary;
    headers['Authorization'] = token ? 'Bearer ' + token : '';
    try {
      const response = await this.httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: combined.buffer.slice(combined.byteOffset, combined.byteOffset + combined.byteLength) as ArrayBuffer,
        connectTimeout: 30000,
        readTimeout: 30000
      });
      const result: ApiResponse<T> = JSON.parse(response.result as string);
      return result;
    } catch (error) {
      Logger.error(TAG, `HTTP multipart请求失败: ${url}`, error as Error);
      return { code: 500, message: '文件上传失败', data: null };
    }
  }

  async chatStream(
    req: AiChatRequest,
    onChunk: (content: string) => void,
    onDone: (conversationId: string, fullContent: string) => void,
    onError: (msg: string) => void
  ): Promise<void> {
    if (!this.httpRequest) {
      this.httpRequest = http.createHttp();
    }
    const url = `${BASE_URL}/api/ai/chat`;
    const token = await this.getToken();
    const headers: Record<string, string> = {};
    headers['Content-Type'] = 'application/json';
    headers['Accept'] = 'text/event-stream';
    headers['Authorization'] = token ? `Bearer ${token}` : '';
    try {
      const response = await this.httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: JSON.stringify(req),
        connectTimeout: 30000,
        readTimeout: 30000
      });
      const body = response.result as string;
      const lines = body.split('\n');
      let fullContent = '';
      let conversationId = '';
      for (const line of lines) {
        const trimmed = line.trim();
        if (trimmed.startsWith('data:')) {
          const payload = trimmed.substring(5).trim();
          if (!payload) continue;
          try {
            const obj: SseChunkMessage = JSON.parse(payload) as SseChunkMessage;
            if (obj.type === 'chunk') {
              fullContent += obj.content || '';
              onChunk(obj.content || '');
            } else if (obj.type === 'done') {
              conversationId = obj.conversation_id || '';
              if (obj.full_content) {
                fullContent = obj.full_content;
              }
              onDone(conversationId, fullContent);
            } else if (obj.type === 'error') {
              onError(obj.message || 'AI 服务错误');
            }
          } catch (e) {
            Logger.warn(TAG, `解析SSE消息失败: ${payload}`);
          }
        }
      }
      if (conversationId === '' && fullContent !== '') {
        onDone('', fullContent);
      }
    } catch (error) {
      Logger.error(TAG, `AI chat请求失败`, error as Error);
      onError('AI 服务暂时不可用，请稍后重试');
    }
  }

  // ============== 社区模块 HTTP 方法 ==============

  // 1. 社区主页
  async fetchCommunityHome(): Promise<ApiResponse<CommunityHomeResponse>> {
    return this.request<CommunityHomeResponse>(
      '/api/community/home',
      http.RequestMethod.GET,
      null,
      true
    );
  }

  // 2. 打卡模块
  async fetchTodayCheckinStatus(): Promise<ApiResponse<TodayCheckinResponse>> {
    return this.request<TodayCheckinResponse>(
      '/api/checkin/today',
      http.RequestMethod.GET,
      null,
      true
    );
  }

  async submitCheckin(req: CheckinSubmitRequest): Promise<ApiResponse<CheckinSubmitResponse>> {
    return this.request<CheckinSubmitResponse>(
      '/api/checkin',
      http.RequestMethod.POST,
      req,
      true
    );
  }

  async fetchCheckinCalendar(year?: number, month?: number): Promise<ApiResponse<CalendarResponse>> {
    const query: Record<string, string | number> = {};
    if (year !== undefined) query['year'] = year;
    if (month !== undefined) query['month'] = month;
    return this.request<CalendarResponse>(
      '/api/checkin/calendar',
      http.RequestMethod.GET,
      null,
      true,
      Object.keys(query).length > 0 ? query : null
    );
  }

  async fetchCheckinRanking(limit: number = 50): Promise<ApiResponse<RankingResponse>> {
    const query: Record<string, string | number> = {};
    query['limit'] = Math.min(50, Math.max(1, limit));
    return this.request<RankingResponse>(
      '/api/checkin/ranking',
      http.RequestMethod.GET,
      null,
      true,
      query
    );
  }

  // 3. 小队模块
  async fetchTeams(subject?: string): Promise<ApiResponse<TeamListResponse>> {
    const query: Record<string, string | number> = {};
    if (subject && subject.length > 0) query['subject'] = subject;
    return this.request<TeamListResponse>(
      '/api/teams',
      http.RequestMethod.GET,
      null,
      true,
      Object.keys(query).length > 0 ? query : null
    );
  }

  async createTeam(req: CreateTeamRequest): Promise<ApiResponse<CreateTeamResponse>> {
    return this.request<CreateTeamResponse>(
      '/api/teams',
      http.RequestMethod.POST,
      req,
      true
    );
  }

  async fetchTeamDetail(id: number): Promise<ApiResponse<TeamDetailResponse>> {
    return this.request<TeamDetailResponse>(
      `/api/teams/${id}`,
      http.RequestMethod.GET,
      null,
      true
    );
  }

  async joinTeam(id: number): Promise<ApiResponse<JoinResponse>> {
    return this.request<JoinResponse>(
      `/api/teams/${id}/join`,
      http.RequestMethod.POST,
      null,
      true
    );
  }

  async fetchApplications(id: number): Promise<ApiResponse<ApplicationsResponse>> {
    return this.request<ApplicationsResponse>(
      `/api/teams/${id}/applications`,
      http.RequestMethod.GET,
      null,
      true
    );
  }

  async processApplication(
    id: number,
    applicationId: number,
    action: string
  ): Promise<ApiResponse<ApplicationProcessResponse>> {
    const req: ApplicationProcessRequest = { action: action };
    return this.request<ApplicationProcessResponse>(
      `/api/teams/${id}/applications/${applicationId}`,
      http.RequestMethod.PUT,
      req,
      true
    );
  }

  async leaveTeam(id: number): Promise<ApiResponse<null>> {
    return this.request<null>(
      `/api/teams/${id}/members`,
      http.RequestMethod.DELETE,
      null,
      true
    );
  }

  async disbandTeam(id: number): Promise<ApiResponse<null>> {
    return this.request<null>(
      `/api/teams/${id}`,
      http.RequestMethod.DELETE,
      null,
      true
    );
  }

  // 4. 考点投票模块
  async fetchVotes(subject?: string): Promise<ApiResponse<VoteListResponse>> {
    const query: Record<string, string | number> = {};
    if (subject && subject.length > 0) query['subject'] = subject;
    return this.request<VoteListResponse>(
      '/api/votes',
      http.RequestMethod.GET,
      null,
      true,
      Object.keys(query).length > 0 ? query : null
    );
  }

  async submitVote(req: SubmitVoteRequest): Promise<ApiResponse<SubmitVoteResponse>> {
    return this.request<SubmitVoteResponse>(
      '/api/votes',
      http.RequestMethod.POST,
      req,
      true
    );
  }

  async voteFor(voteId: number): Promise<ApiResponse<VoteResultResponse>> {
    return this.request<VoteResultResponse>(
      `/api/votes/${voteId}/vote`,
      http.RequestMethod.POST,
      null,
      true
    );
  }

  async fetchMyVotes(): Promise<ApiResponse<MyVoteListResponse>> {
    return this.request<MyVoteListResponse>(
      '/api/votes/my-votes',
      http.RequestMethod.GET,
      null,
      true
    );
  }

  async fetchMySubmissions(): Promise<ApiResponse<MySubmissionsResponse>> {
    return this.request<MySubmissionsResponse>(
      '/api/votes/my-submissions',
      http.RequestMethod.GET,
      null,
      true
    );
  }

  async fetchPendingSubmissions(): Promise<ApiResponse<PendingSubmissionsResponse>> {
    return this.request<PendingSubmissionsResponse>(
      '/api/votes/pending-submissions',
      http.RequestMethod.GET,
      null,
      true
    );
  }

  // 5. 资料上传模块
  async uploadResource(
    fileBuffer: ArrayBuffer,
    fileName: string,
    fields: Record<string, string>
  ): Promise<ApiResponse<UploadResourceResponse>> {
    return this.requestMultipartWithFields<UploadResourceResponse>(
      '/api/resources',
      fileBuffer,
      fileName,
      fields
    );
  }

  async fetchMyUploads(): Promise<ApiResponse<MyUploadListResponse>> {
    return this.request<MyUploadListResponse>(
      '/api/resources/my-uploads',
      http.RequestMethod.GET,
      null,
      true
    );
  }

  // 带多字段的multipart上传
  private async requestMultipartWithFields<T>(
    path: string,
    fileBuffer: ArrayBuffer,
    fileName: string,
    fields: Record<string, string>
  ): Promise<ApiResponse<T>> {
    if (!this.httpRequest) {
      this.httpRequest = http.createHttp();
    }
    const url = `${BASE_URL}${path}`;
    const token = await this.getToken();
    const boundary = '---xiaokaoxing-resource-boundary';

    let bodyStr = '';
    for (const key of Object.keys(fields)) {
      bodyStr += `--${boundary}\r\n`;
      bodyStr += `Content-Disposition: form-data; name="${key}"\r\n\r\n`;
      bodyStr += `${fields[key]}\r\n`;
    }
    bodyStr += `--${boundary}\r\n`;
    bodyStr += `Content-Disposition: form-data; name="file"; filename="${fileName}"\r\n`;
    bodyStr += `Content-Type: application/octet-stream\r\n\r\n`;
    const headerBytes = new Uint8Array(bodyStr.length);
    for (let i = 0; i < bodyStr.length; i++) headerBytes[i] = bodyStr.charCodeAt(i);

    const footerStr = `\r\n--${boundary}--\r\n`;
    const footerBytes = new Uint8Array(footerStr.length);
    for (let i = 0; i < footerStr.length; i++) footerBytes[i] = footerStr.charCodeAt(i);

    const totalLen = headerBytes.length + fileBuffer.byteLength + footerBytes.length;
    const combined = new Uint8Array(totalLen);
    combined.set(headerBytes, 0);
    combined.set(new Uint8Array(fileBuffer), headerBytes.length);
    combined.set(footerBytes, headerBytes.length + fileBuffer.byteLength);

    const headers: Record<string, string> = {};
    headers['Content-Type'] = `multipart/form-data; boundary=${boundary}`;
    headers['Authorization'] = token ? `Bearer ${token}` : '';
    try {
      const response = await this.httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: combined.buffer.slice(combined.byteOffset, combined.byteOffset + combined.byteLength) as ArrayBuffer,
        connectTimeout: 60000,
        readTimeout: 60000
      });
      const result: ApiResponse<T> = JSON.parse(response.result as string);
      return result;
    } catch (error) {
      Logger.error(TAG, `HTTP multipart+fields请求失败: ${url}`, error as Error);
      return { code: 500, message: '文件上传失败', data: null };
    }
  }

  // ============== 工具模块 HTTP 方法 ==============

  // 1. 工具箱主页聚合
  async fetchToolboxHome(): Promise<ApiResponse<ToolboxHomeResponse>> {
    return this.request<ToolboxHomeResponse>('/api/toolbox/home', http.RequestMethod.GET, null, true);
  }

  // 2. 每日一问
  async fetchDailyQuestionToday(): Promise<ApiResponse<DailyQuestionToday>> {
    return this.request<DailyQuestionToday>('/api/daily-question/today', http.RequestMethod.GET, null, true);
  }
  async submitDailyAnswer(req: SubmitDailyAnswerRequest): Promise<ApiResponse<SubmitDailyAnswerData>> {
    return this.request<SubmitDailyAnswerData>('/api/daily-question/answer', http.RequestMethod.POST, req, true);
  }
  async fetchDailyQuestionHistory(month: string | null = null, onlyWrong: boolean = false):
    Promise<ApiResponse<DailyQuestionHistoryResponse>> {
    const query: Record<string, string | number> = {};
    if (month) query['month'] = month;
    if (onlyWrong) query['only_wrong'] = '1';
    return this.request<DailyQuestionHistoryResponse>(
      '/api/daily-question/history',
      http.RequestMethod.GET, null, true,
      Object.keys(query).length > 0 ? query : null
    );
  }

  // 3. 学习笔记
  async fetchNotes(tag: string | null = null, keyword: string | null = null,
    limit: number = 20, offset: number = 0): Promise<ApiResponse<NoteListResponse>> {
    const query: Record<string, string | number> = {};
    if (tag) query['tag'] = tag;
    if (keyword) query['keyword'] = keyword;
    query['limit'] = limit;
    query['offset'] = offset;
    return this.request<NoteListResponse>('/api/notes', http.RequestMethod.GET, null, true, query);
  }
  async createNote(req: CreateNoteRequest): Promise<ApiResponse<NoteDetailResponse>> {
    return this.request<NoteDetailResponse>('/api/notes', http.RequestMethod.POST, req, true);
  }
  async fetchNoteDetail(id: number): Promise<ApiResponse<NoteDetailResponse>> {
    return this.request<NoteDetailResponse>(`/api/notes/${id}`, http.RequestMethod.GET, null, true);
  }
  async updateNote(id: number, req: UpdateNoteRequest): Promise<ApiResponse<UpdateNoteResponse>> {
    return this.request<UpdateNoteResponse>(`/api/notes/${id}`, http.RequestMethod.PUT, req, true);
  }
  async deleteNote(id: number): Promise<ApiResponse<null>> {
    return this.request<null>(`/api/notes/${id}`, http.RequestMethod.DELETE, null, true);
  }
  async excerptNote(req: ExcerptNoteRequest): Promise<ApiResponse<NoteDetailResponse>> {
    return this.request<NoteDetailResponse>('/api/notes/excerpt', http.RequestMethod.POST, req, true);
  }
  async toggleNotePin(id: number, isPinned: boolean): Promise<ApiResponse<TogglePinResponse>> {
    const req: TogglePinRequest = { is_pinned: isPinned };
    return this.request<TogglePinResponse>(`/api/notes/${id}/pin`, http.RequestMethod.PUT, req, true);
  }

  // 4. 绩点计算器
  async fetchSemesters(): Promise<ApiResponse<SemesterListResponse>> {
    return this.request<SemesterListResponse>('/api/gpa/semesters', http.RequestMethod.GET, null, true);
  }
  async createSemester(req: CreateSemesterRequest): Promise<ApiResponse<SemesterItem>> {
    return this.request<SemesterItem>('/api/gpa/semesters', http.RequestMethod.POST, req, true);
  }
  async deleteSemester(id: number): Promise<ApiResponse<null>> {
    return this.request<null>(`/api/gpa/semesters/${id}`, http.RequestMethod.DELETE, null, true);
  }
  async fetchCourses(semesterId: number): Promise<ApiResponse<CourseListResponse>> {
    const query: Record<string, string | number> = {};
    query['semester_id'] = semesterId;
    return this.request<CourseListResponse>('/api/gpa/courses', http.RequestMethod.GET, null, true, query);
  }
  async saveCourse(req: SaveCourseRequest): Promise<ApiResponse<SaveCourseResponse>> {
    return this.request<SaveCourseResponse>('/api/gpa/courses', http.RequestMethod.POST, req, true);
  }
  async deleteCourse(id: number): Promise<ApiResponse<null>> {
    return this.request<null>(`/api/gpa/courses/${id}`, http.RequestMethod.DELETE, null, true);
  }
  async calculateGpa(algorithm: string = 'standard'): Promise<ApiResponse<GpaCalculateResponse>> {
    const query: Record<string, string | number> = {};
    query['algorithm'] = algorithm;
    return this.request<GpaCalculateResponse>('/api/gpa/calculate', http.RequestMethod.GET, null, true, query);
  }

  // 5. 个人文档库
  async fetchDocuments(category: string | null = null,
    limit: number = 20, offset: number = 0): Promise<ApiResponse<DocumentListResponse>> {
    const query: Record<string, string | number> = {};
    if (category) query['category'] = category;
    query['limit'] = limit;
    query['offset'] = offset;
    return this.request<DocumentListResponse>('/api/documents', http.RequestMethod.GET, null, true, query);
  }
  async fetchStorageStatus(): Promise<ApiResponse<StorageStatusResponse>> {
    return this.request<StorageStatusResponse>('/api/documents/storage', http.RequestMethod.GET, null, true);
  }
  async updateDocOffline(id: number, isOffline: boolean): Promise<ApiResponse<UpdateDocOfflineResponse>> {
    const req: UpdateDocOfflineRequest = { is_offline: isOffline };
    return this.request<UpdateDocOfflineResponse>(`/api/documents/${id}/offline`,
      http.RequestMethod.PUT, req, true);
  }
  async deleteDocument(id: number): Promise<ApiResponse<null>> {
    return this.request<null>(`/api/documents/${id}`, http.RequestMethod.DELETE, null, true);
  }

  // 6. 精选书签
  async fetchBookmarks(color: string | null = null,
    keyword: string | null = null): Promise<ApiResponse<BookmarkListResponse>> {
    const query: Record<string, string | number> = {};
    if (color) query['color'] = color;
    if (keyword) query['keyword'] = keyword;
    return this.request<BookmarkListResponse>('/api/bookmarks', http.RequestMethod.GET, null, true, query);
  }
  async createBookmark(req: CreateBookmarkRequest): Promise<ApiResponse<CreateBookmarkResponse>> {
    return this.request<CreateBookmarkResponse>('/api/bookmarks', http.RequestMethod.POST, req, true);
  }
  async updateBookmark(id: number, req: UpdateBookmarkRequest): Promise<ApiResponse<UpdateBookmarkResponse>> {
    return this.request<UpdateBookmarkResponse>(`/api/bookmarks/${id}`, http.RequestMethod.PUT, req, true);
  }
  async deleteBookmark(id: number): Promise<ApiResponse<null>> {
    return this.request<null>(`/api/bookmarks/${id}`, http.RequestMethod.DELETE, null, true);
  }

  // ============== 我的页模块 HTTP 方法 ==============

  // 1. 用户信息
  async fetchUserMe(): Promise<ApiResponse<UserMeInfo>> {
    return this.request<UserMeInfo>('/api/users/me', http.RequestMethod.GET, null, true);
  }
  async updateUserMe(req: UpdateUserMeRequest): Promise<ApiResponse<UserMeInfo>> {
    return this.request<UserMeInfo>('/api/users/me', http.RequestMethod.PUT, req, true);
  }

  // 2. 聚合统计（打卡 + 学习数据 + 我的内容数量）
  async fetchUserStats(): Promise<ApiResponse<UserStatsAggregate>> {
    return this.request<UserStatsAggregate>('/api/users/me/stats', http.RequestMethod.GET, null, true);
  }

  // 3. 学习数据概览（独立接口）
  async fetchLearningStats(): Promise<ApiResponse<LearningStatsResponse>> {
    return this.request<LearningStatsResponse>('/api/users/me/learning-stats', http.RequestMethod.GET, null, true);
  }

  // 4. 我的小队
  async fetchMyTeams(): Promise<ApiResponse<MyTeamsListResponse>> {
    return this.request<MyTeamsListResponse>('/api/teams/my-teams', http.RequestMethod.GET, null, true);
  }

  // 5. 通知设置
  async fetchNotificationSettings(): Promise<ApiResponse<NotificationSettingsResponse>> {
    return this.request<NotificationSettingsResponse>('/api/settings/notifications', http.RequestMethod.GET, null, true);
  }
  async updateNotificationSettings(req: UpdateNotificationSettingsRequest):
    Promise<ApiResponse<NotificationSettingsResponse>> {
    return this.request<NotificationSettingsResponse>('/api/settings/notifications', http.RequestMethod.PUT, req, true);
  }

  // 6. 关于信息
  async fetchAboutInfo(): Promise<ApiResponse<AboutInfoResponse>> {
    return this.request<AboutInfoResponse>('/api/settings/about', http.RequestMethod.GET, null, false);
  }

  // 7. 退出登录
  async logout(): Promise<ApiResponse<null>> {
    return this.request<null>('/api/auth/logout', http.RequestMethod.POST, null, true);
  }

  destroy(): void {
    if (this.httpRequest) {
      this.httpRequest.destroy();
      this.httpRequest = null;
    }
  }
}

export const apiService: ApiService = new ApiService();
// export type {
//   Major,
//   RegisterRequest,
//   RegisterData,
//   ApiResponse,
//   LoginRequest,
//   AuthData,
//   UserInfo
// };
