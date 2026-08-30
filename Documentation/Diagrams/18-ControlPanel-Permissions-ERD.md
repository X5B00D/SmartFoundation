# ERD حي لـControlPanel والصلاحيات

> إعداد الطباعة: A4 أفقي. الخطوط المتصلة FKs حية. الخطوط المتقطعة علاقات مستنتجة وليست قيوداً فعلية.

```mermaid
%%{init: {"theme":"neutral","er":{"layoutDirection":"LR"}}}%%
erDiagram
  Program ||--o{ Menu : "FK programID_FK"
  Menu ||--o{ MenuDistributor : "FK menuID_FK"
  Distributor ||--o{ MenuDistributor : "FK distributorID_FK"
  Role ||--o{ MenuDistributor : "FK roleID_FK"
  Users ||--o{ MenuDistributor : "FK userID_FK"
  Distributor ||--o{ DistributorPermissionType : "FK"
  PermissionType ||--o{ DistributorPermissionType : "FK"
  DistributorPermissionType ||--o{ Permission : "FK"
  Users ||--o{ Permission : "FK"
  Role ||--o{ Permission : "FK"
  Distributor ||--o{ Permission : "FK"
  DeptSecDiv ||--o{ Permission : "FK"
  Users ||--o{ UserDistributor : "FK"
  Distributor ||--o{ UserDistributor : "FK"
  Users ||--o{ UsersDetails : "FK"
  Users ||--o{ UsersPassword : "FK"
  Notifications ||--o{ UserNotifications : "FK"
  Users ||--o{ UserNotifications : "FK"
```

العلاقات التالية لا تظهر في Mermaid كـFK: `Menu.parentMenuID_FK -> Menu`، و`Permission.IdaraID_FK/InIdaraID -> Idara`، و`DeptSecDiv.OrganizationID_FK/idaraID_FK`؛ كلها علاقات مستنتجة وليست قيوداً فعلية.

