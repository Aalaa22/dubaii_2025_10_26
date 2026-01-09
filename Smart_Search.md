# دليل واجهة البحث الذكي (Smart Search) عبر الأقسام

هذا الدليل يوضح نقاط النهاية العامة للبحث الذكي عبر أقسام المنصة (مطاعم، عقارات، خدمات السيارات، إيجار سيارات، بيع سيارات، إلكترونيات، خدمات أخرى)، مع شرح بارامترات البحث، الفرز، أمثلة الاستخدام، وشكل الاستجابة.

## نظرة عامة
- البحث الذكي يدعم تمرير قيم متعددة في معظم الفلاتر بإحدى الصيغ: نص مفصول بفواصل (`Dubai,Abu Dhabi`) أو كمصفوفة (`emirate[]=Dubai&emirate[]=Abu Dhabi`).
- البحث بالكلمة المفتاحية غالبًا يشمل حقول العنوان والوصف وغيرها حسب القسم.
- خيارات الفرز الشائعة: `sort_by=latest | most_viewed | rank`، وبعض الأقسام تضيف خيارات إضافية.
- أغلب مسارات البحث تُرجع نتائج مُقسّمة صفحات (Paginated) ضمن غلاف موحّد.

## المطاعم (Restaurants)
- المسارات:
  - `GET /api/restaurants/search` — بحث ذكي مع تحقق للمدخلات، ويرجع نتائج `paginate`.
  - `GET /api/restaurants` — فهرس عام بنفس منطق البحث تقريبًا، ويرجع نتائج `paginate`.
  - `GET /api/restaurants/offers-box/ads` — إعلانات صندوق العروض مع `paginate`.
- بارامترات البحث:
  - `emirate`, `district`, `area`, `price_range`, `category` — تقبل قيمة مفردة أو متعددة.
  - `keyword` — بحث في `title`, `description`, `category`.
  - `sort_by` — `latest | most_viewed | rank`.
  - `per_page` — يُستخدم في جميع المسارات ويحدد حجم الصفحة (1..50).
- أمثلة:
  - `GET /api/restaurants/search?emirate=Dubai&category=Fast%20Food&keyword=Pizza&sort_by=most_viewed`
  - `GET /api/restaurants/offers-box/ads?emirate=Dubai&per_page=12`

## العقارات (Real Estates)
- المسارات:
  - `GET /api/real-estates/search`
  - `GET /api/real-estates/offers-box/ads`
- بارامترات البحث:
  - `emirate`, `district`, `area` — تحديد الموقع.
  - `contract_type` — نوع العقد: `Sale`, `Rent`.
  - `property_type` — نوع العقار.
  - `price_range` — نطاق السعر.
  - `keyword` — بحث نصي مرن.
  - `sort_by` — `latest | most_viewed | rank`.
  - `per_page` — حجم الصفحة.
- أمثلة:
  - `GET /api/real-estates/search?property_type=Apartment,Villa&emirate=Dubai&district=Marina`

## خدمات السيارات (Car Services)
- المسارات:
  - `GET /api/car-services/search`
  - `GET /api/car-services/offers-box/ads`
- بارامترات البحث:
  - `service_type` — نوع الخدمة.
  - `emirate`, `district`, `area` — الموقع.
  - `min_price`, `max_price` — نطاق السعر.
  - `keyword` — بحث في العنوان/الوصف/اسم الخدمة.
  - `sort_by` — `latest | price_low | price_high | most_viewed`.
  - `per_page` — حجم الصفحة.
- أمثلة:
  - `GET /api/car-services/search?emirate=Dubai&service_type=car_wash&keyword=تنظيف&sort_by=price_low&per_page=10`

## إيجار السيارات (Car Rent)
- المسارات:
  - `GET /api/car-rent/search`
  - `GET /api/car-rent/offers-box/ads`
- بارامترات البحث:
  - `make`, `model`, `trim`, `year` — مواصفات السيارة.
  - `emirate`, `district`, `area` — الموقع.
  - `price_range` — نطاق السعر العام.
  - `day_rent_range`, `month_rent_range` — نطاقات الإيجار اليومي/الشهري.
  - `keyword` — بحث نصي.
  - `sort_by` — `latest | most_viewed | rank`.
  - `per_page` — حجم الصفحة.
- أمثلة:
  - `GET /api/car-rent/search?make=Toyota,Honda&model=Camry,Accord&year=2021,2022&emirate=Dubai`

## بيع السيارات (Car Sales)
- المسارات:
  - `GET /api/car-sales-ads/search`
  - `GET /api/car-sales-ads/offers-box/ads`
- بارامترات البحث (شائعة):
  - `make`, `model`, `trim`, `year` — مواصفات.
  - `emirate`, `district`, `area` — الموقع.
  - `price_range` — نطاق السعر.
  - `keyword` — بحث نصي.
  - `sort_by` — خيارات الفرز المتاحة بالقسم.
  - `per_page` — حجم الصفحة.
- أمثلة:
  - `GET /api/car-sales-ads/search?make=Toyota&model=Camry&year=2020,2021&emirate=Dubai`

## الإلكترونيات (Electronics)
- المسارات:
  - `GET /api/electronics/search`
  - `GET /api/electronics/offers-box/ads`
- بارامترات البحث:
  - `section_type` — قسم الإلكترونيات.
  - `brand` — العلامة التجارية.
  - `product_name` — اسم المنتج.
  - `emirate`, `district` — الموقع.
  - `warranty` — ضمان (true/false).
  - `min_price`, `max_price` — السعر.
  - `keyword` — بحث في العنوان/الوصف/الاسم/العلامة/القسم.
  - `sort_by` — `latest | most_viewed | rank | price_low | price_high`.
  - `per_page` — حجم الصفحة.
- أمثلة:
  - `GET /api/electronics/search?brand=Samsung,Apple&section_type=Smartphones&keyword=gaming&sort_by=price_low`
  - `GET /api/electronics/offers-box/ads?per_page=8`

## خدمات أخرى (Other Services)
- المسارات:
  - `GET /api/other-services/search`
  - `GET /api/other-services/offers-box/ads`
- بارامترات البحث (شائعة):
  - `emirate`, `district`, `area` — الموقع.
  - `price_range` — نطاق السعر.
  - `keyword` — بحث نصي في العنوان/الوصف.
  - `sort_by` — خيارات الفرز المتاحة بالقسم.
  - `per_page` — حجم الصفحة.
- أمثلة:
  - `GET /api/other-services/search?emirate=Dubai&district=Deira&keyword=cleaning`

## ملاحظات حول الوظائف (Jobs)
- مسار البحث الذكي للوظائف مفعّل: `GET /api/jobs/search` مع فلاتر متعددة وقابلة للفرز.
- تتوفر أيضًا مسارات العرض والفهرس والصندوق: `GET /api/jobs`, `GET /api/jobs/offers-box/ads`, `GET /api/jobs/{id}`.

## شكل الاستجابة (Response)
- جميع مسارات البحث تُرجع نتائج `paginate` ضمن غلاف موحّد بالشكل:
  - `success: boolean`
  - `data: array|object` — العناصر أو البيانات المطلوب عرضها
  - `meta: object` — معلومات الصفحات: `current_page`, `per_page`, `total`, `last_page`, `from`, `to`

مثال مبسّط لاستجابة مُقسّمة صفحات:
```json
{
  "success": true,
  "data": [{ "id": 1, "title": "Ad Title" }],
  "meta": {
    "current_page": 1,
    "per_page": 15,
    "total": 67,
    "last_page": 5,
    "from": 1,
    "to": 15
  }
}
```

## ملاحظات عامة
- القيم المتعددة: استخدم فاصلة للفصل أو صيغة المصفوفة.
- حساسية الأحرف: البحث غير حساس لحالة الأحرف غالبًا.
- المطابقة الجزئية: يتم استخدام `LIKE` مع Wildcards في البحث بالكلمات.
- الأداء: يُنصح بإضافة فهارس على الحقول الأكثر استخدامًا في البحث.
- الأخطاء: تتّبع الواجهات رموز HTTP القياسية (`200`, `400`, `422`, `500`).

## ملاحظات تقنية مهمة
- تم التحقق من المسارات في `routes/api.php` لهذا المشروع؛ الأقسام التالية تدعم مسار `/search`: `restaurants`, `real-estates`, `car-services`, `car-rent`, `electronics`, `other-services`, `jobs`.
- مسارات صندوق العروض (Offers Box) موحّدة بالشكل: `GET /api/<section>/offers-box/ads`، مثال: `GET /api/restaurants/offers-box/ads`, `GET /api/jobs/offers-box/ads`.
- جميع مسارات العروض تعتمد `per_page` للتحكم في حجم الصفحة؛ يفضّل عدم استخدام `limit`.

انتهى.