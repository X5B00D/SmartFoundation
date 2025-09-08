namespace SmartFoundation.UI.ViewModels.SmartCard;

public class SmartCardModel
{
    public string? Title { get; set; }
    public string? BodyHtml { get; set; }
    public string? BadgeText { get; set; }
    public List<CardButton> Buttons { get; set; } = new();

    public string CardClasses { get; set; } = "bg-white rounded-2xl shadow p-6";
    public string HeaderClasses { get; set; } = "mb-4 flex items-center justify-between";
    public string TitleClasses { get; set; } = "text-lg font-semibold";
    public string BodyClasses { get; set; } = "prose max-w-none";
    public string FooterClasses { get; set; } = "mt-5 flex gap-2";
}

public class CardButton
{
    public string Text { get; set; } = "Action";
    public string? Icon { get; set; }
    public string Href { get; set; } = "#";
    public string Type { get; set; } = "button"; // button | link | submit
    public string Classes { get; set; } = "inline-flex items-center gap-2 px-4 py-2 rounded-xl";
    public string? Tooltip { get; set; }
    public string? AlpineClick { get; set; }
    public bool Outline { get; set; } = false;
    public bool LoadingOnClick { get; set; } = false;
}
