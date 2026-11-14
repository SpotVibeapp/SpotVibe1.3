import '../l10n/app_localizations.dart';
import '../models/gem.dart';

String gemCategoryLabel(GemCategory category, AppLocalizations l10n) {
  switch (category) {
    case GemCategory.trail:
      return l10n.gemCategoryHikingTrails;
    case GemCategory.bikeTrail:
      return l10n.gemCategoryBikeTrails;
    case GemCategory.park:
      return l10n.gemCategoryParks;
    case GemCategory.viewpoint:
      return l10n.gemCategoryViewpoints;
    case GemCategory.water:
      return l10n.gemCategoryCommunityPools;
    case GemCategory.nature:
      return l10n.gemCategoryNature;
    case GemCategory.museum:
      return l10n.gemCategoryMuseums;
    case GemCategory.art:
      return l10n.gemCategoryArt;
    case GemCategory.historic:
      return l10n.gemCategoryHistoric;
    case GemCategory.landmark:
      return l10n.gemCategoryLandmarks;
    case GemCategory.foodDrink:
      return l10n.gemCategoryRestaurants;
    case GemCategory.attraction:
      return l10n.gemCategoryAttractions;
    case GemCategory.other:
      return l10n.gemCategoryOther;
  }
}
