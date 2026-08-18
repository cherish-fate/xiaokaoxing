import { TagStyle } from '../utils/Constants';

export class RecommendationItemModel {
  id: number;
  emoji: string;
  description: string;
  suggestion: string;
  targetType: string;
  targetId: number;

  constructor(
    id: number,
    emoji: string,
    description: string,
    suggestion: string,
    targetType: string,
    targetId: number
  ) {
    this.id = id;
    this.emoji = emoji;
    this.description = description;
    this.suggestion = suggestion;
    this.targetType = targetType;
    this.targetId = targetId;
  }
}

@Observed
export class PrepResourceItemModel {
  id: number;
  title: string;
  category: string;
  typeTag: string;
  isHot: boolean;
  author: string;
  createdAt: string;
  viewCount: number;
  isFavorited: boolean;
  fileUrl: string;

  constructor(
    id: number,
    title: string,
    category: string,
    typeTag: string,
    isHot: boolean,
    author: string,
    createdAt: string,
    viewCount: number,
    isFavorited: boolean,
    fileUrl: string
  ) {
    this.id = id;
    this.title = title;
    this.category = category;
    this.typeTag = typeTag;
    this.isHot = isHot;
    this.author = author;
    this.createdAt = createdAt;
    this.viewCount = viewCount;
    this.isFavorited = isFavorited;
    this.fileUrl = fileUrl;
  }

  shortDate(): string {
    if (!this.createdAt) return '';
    if (this.createdAt.length >= 8) {
      return '20' === this.createdAt.substring(0, 2)
        ? this.createdAt.substring(2)
        : this.createdAt;
    }
    return this.createdAt;
  }

  categoryTagBg(): string {
    if (this.category.indexOf('真题') >= 0) return TagStyle.BLUE;
    if (this.category.indexOf('提纲') >= 0) return TagStyle.ORANGE;
    if (this.category.indexOf('考点') >= 0) return TagStyle.GREEN;
    if (this.category.indexOf('题库') >= 0) return TagStyle.PURPLE;
    return TagStyle.BLUE;
  }

  categoryTagColor(): string {
    if (this.category.indexOf('真题') >= 0) return '#4A7FFF';
    if (this.category.indexOf('提纲') >= 0) return '#FF7E02';
    if (this.category.indexOf('考点') >= 0) return '#38CFC9';
    if (this.category.indexOf('题库') >= 0) return '#7C5CFF';
    return '#4A7FFF';
  }

  iconBg(): string {
    return this.categoryTagBg();
  }

  iconEmoji(): string {
    if (this.category.indexOf('真题') >= 0) return '📄';
    if (this.category.indexOf('提纲') >= 0) return '📋';
    if (this.category.indexOf('考点') >= 0) return '🎯';
    if (this.category.indexOf('题库') >= 0) return '✏️';
    return '📁';
  }

  typeTagBg(): string {
    if (this.typeTag.indexOf('本校') >= 0) return TagStyle.BLUE;
    if (this.typeTag.indexOf('高频') >= 0 || this.typeTag.indexOf('必考') >= 0) return TagStyle.ORANGE;
    return TagStyle.GREEN;
  }

  typeTagColor(): string {
    if (this.typeTag.indexOf('本校') >= 0) return '#4A7FFF';
    if (this.typeTag.indexOf('高频') >= 0 || this.typeTag.indexOf('必考') >= 0) return '#FF7E02';
    return '#38CFC9';
  }
}

export class PrepPageModel {
  recommendations: RecommendationItemModel[];
  resources: PrepResourceItemModel[];
  resourcesTotal: number;

  constructor(
    recommendations: RecommendationItemModel[],
    resources: PrepResourceItemModel[],
    resourcesTotal: number
  ) {
    this.recommendations = recommendations;
    this.resources = resources;
    this.resourcesTotal = resourcesTotal;
  }

  static empty(): PrepPageModel {
    return new PrepPageModel([], [], 0);
  }
}
