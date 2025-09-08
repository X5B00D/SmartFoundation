namespace SmartFoundation.UI.ViewModels.SmartForm.Helpers
{
    public static class FormButtonFactory
    {
        public static void Normalize(FormButtonConfig btn)
        {
            var op = btn.Operation?.ToLowerInvariant()?.Trim() ?? "custom";

            switch (op)
            {
                case "insert":
                case "save":
                    btn.Text ??= "حفظ";
                    btn.Type = "submit";
                    btn.Icon ??= "fa fa-save";
                    btn.Color ??= "success";
                    break;

                case "reset":
                    btn.Text ??= "تفريغ";
                    btn.Type = "reset";
                    btn.Icon ??= "fa fa-eraser";
                    btn.Color ??= "secondary";
                    break;

                case "cancel":
                    btn.Text ??= "إلغاء";
                    btn.Type = "button";
                    btn.Icon ??= "fa fa-times";
                    btn.Color ??= "secondary";
                    btn.OnClickJs ??= "cancelForm()";
                    break;

                case "edit":
                    btn.Text ??= "تعديل";
                    btn.Type = "button";
                    btn.Icon ??= "fa fa-edit";
                    btn.Color ??= "info";
                    btn.OnClickJs ??= "editForm()";
                    break;

                case "delete":
                    btn.Text ??= "حذف";
                    btn.Type = "button";
                    btn.Icon ??= "fa fa-trash";
                    btn.Color ??= "danger";
                    var delSp = btn.StoredProcedureName ?? "";
                    btn.OnClickJs ??= $"submitForm(null, 'POST', true, '{delSp}')";
                    break;

                case "execute":
                    btn.Text ??= "تنفيذ";
                    btn.Type = "button";
                    btn.Icon ??= "fa fa-play";
                    btn.Color ??= "info";
                    var sp = btn.StoredProcedureName ?? "";
                    btn.OnClickJs ??= $"submitForm(null, 'POST', true, '{sp}')";
                    break;

                default:
                    btn.Text ??= "زر مخصص";
                    btn.Type = "button";
                    btn.Icon ??= "fa fa-circle";
                    btn.Color ??= "secondary";
                    break;
            }
        }
    }
}
