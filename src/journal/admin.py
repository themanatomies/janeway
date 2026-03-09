__copyright__ = "Copyright 2017 Birkbeck, University of London"
__author__ = "Martin Paul Eve & Andy Byers"
__license__ = "AGPL v3"
__maintainer__ = "Birkbeck Centre for Technology and Publishing"

from django.contrib import admin
from django.template.defaultfilters import truncatewords
from django.conf import settings
from django import forms

from journal import models
from press import models as press_models
from utils import admin_utils


class JournalAdminForm(forms.ModelForm):
    """Custom form for Journal admin that handles path-based routing."""
    
    class Meta:
        model = models.Journal
        fields = '__all__'
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # If using path-based routing, make press_association required
        if settings.URL_CONFIG == "path":
            self.fields['press_association'].required = True
            self.fields['press_association'].help_text = (
                "Required for path-based routing. The domain will be set to this press's domain."
            )
    
    def clean(self):
        cleaned_data = super().clean()
        if settings.URL_CONFIG == "path":
            press_association = cleaned_data.get('press_association')
            if not press_association:
                raise forms.ValidationError(
                    "Press association is required when using path-based URL routing."
                )
        return cleaned_data


class IssueAdmin(admin.ModelAdmin):
    list_display = (
        "pk",
        "issue_title",
        "volume",
        "issue",
        "date",
        "journal",
        "issue_type",
    )
    list_display_links = ("pk", "issue_title")
    list_filter = ("journal", "date")
    search_fields = ("pk", "issue_title", "volume", "issue", "journal__code")
    date_hierarchy = "date"
    filter_horizontal = ("articles",)
    raw_id_fields = ("issue_type",)

    inlines = [
        admin_utils.IssueGalleyInline,
        admin_utils.SectionOrderingInline,
        admin_utils.ArticleOrderingInline,
    ]


class IssueTypeAdmin(admin.ModelAdmin):
    list_display = ("code", "pretty_name", "journal")
    list_filter = ("journal",)
    search_fields = ("code", "pretty_name")


class IssueGalleyAdmin(admin.ModelAdmin):
    list_display = ("pk", "file", "issue", "_journal")
    list_display_links = ("pk", "file")
    list_filter = ("issue__journal",)
    search_fields = (
        "pk",
        "file__original_filename",
        "issue__journal__code",
        "issue__issue_title",
        "issue__volume",
        "issue__issue",
    )

    def _journal(self, obj):
        return obj.issue.journal if obj else ""


class IssueEditorAdmin(admin.ModelAdmin):
    list_display = ("account", "_issue", "_journal", "role")
    list_filter = (
        "issue__journal",
        "role",
    )
    search_fields = (
        "account__email",
        "account__first_name",
        "account__last_name",
        "role",
        "issue__issue_title",
        "issue__journal__code",
    )

    raw_id_fields = ("account", "issue")

    def _journal(self, obj):
        return obj.issue.journal if obj else ""

    def _issue(self, obj):
        return truncatewords(obj.issue.__str__(), 10)


class JournalAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "code",
        "domain",
        "is_remote",
        "is_conference",
        "hide_from_press",
    )
    list_filter = ("is_remote", "is_conference", "hide_from_press")
    raw_id_fields = (
        "carousel",
        "current_issue",
        "thumbnail_image",
        "xsl",
    )
    filter_horizontal = ("keywords",)
    form = JournalAdminForm
    
    def save_model(self, request, obj, form, change):
        """Override save to handle path-based routing configuration."""
        # If using path-based routing, set domain to press domain
        if settings.URL_CONFIG == "path":
            if obj.press_association:
                obj.domain = obj.press_association.domain
        super().save_model(request, obj, form, change)
        
        # After saving, ensure the journal is in press_press_featured_journals
        if obj.press_association:
            from press.models import Press
            press_press_featured_journals = Press._meta.get_field(
                'featured_journals'
            ).remote_field.through
            press_press_featured_journals.objects.get_or_create(
                press_id=obj.press_association.id,
                journal_id=obj.id
            )


class PinnedArticleAdmin(admin.ModelAdmin):
    list_display = ("article", "journal", "sequence")
    list_filter = ("journal",)
    search_fields = ("journal__code", "article__title")
    raw_id_fields = ("article",)


class BannedIPAdmin(admin.ModelAdmin):
    list_display = ("ip", "date_banned")
    list_filter = ("date_banned",)
    search_fields = ("ip",)
    date_hierarchy = "date_banned"


class NotificationsAdmin(admin.ModelAdmin):
    list_display = ("journal", "user", "domain", "type", "active")
    list_filter = ("journal", "domain", "type", "active")
    search_fields = (
        "journal__code",
        "user__email",
        "user__first_name",
        "user__last_name",
        "domain",
        "type",
    )
    raw_id_fields = ("user",)


class ArticleOrderingAdmin(admin_utils.ArticleFKModelAdmin):
    list_display = ("order", "_article", "_issue", "_section", "_journal")
    list_filter = ("article__journal",)
    search_fields = (
        "article__title",
        "section__name",
        "issue__issue_title",
        "issue__journal__code",
        "issue__volume",
        "issue__issue",
    )
    raw_id_fields = ("article",)

    def _issue(self, obj):
        return truncatewords(obj.issue.__str__(), 10)

    def _section(self, obj):
        return truncatewords(obj.issue.__str__(), 10)


class FixedPubCheckItemsAdmin(admin_utils.ArticleFKModelAdmin):
    list_display = (
        "_article",
        "_journal",
        "metadata",
        "verify_doi",
        "select_issue",
        "set_pub_date",
        "send_notifications",
        "select_render_galley",
        "select_article_image",
        "select_open_reviews",
    )
    list_filter = (
        "article__journal",
        "metadata",
        "verify_doi",
        "select_issue",
        "set_pub_date",
        "send_notifications",
        "select_render_galley",
        "select_article_image",
        "select_open_reviews",
    )
    search_fields = ("article__pk", "article__title", "article__journal__code")
    raw_id_fields = ("article",)


class PresetPublicationCheckItemAdmin(admin.ModelAdmin):
    list_display = ("journal", "title", "enabled")
    list_filter = ("journal", "enabled")
    search_fields = ("journal__code", "title", "text")


class PrePublicationChecklistItemAdmin(admin_utils.ArticleFKModelAdmin):
    list_display = ("_article", "_journal", "completed", "completed_by", "completed_on")
    list_filter = ("article__journal", "completed", "completed_on")
    search_fields = (
        "article__title",
        "article__journal__code",
        "completed_by__email",
        "completed_by__first_name",
        "completed_by__last_name",
    )
    date_hierarchy = "completed_on"
    raw_id_fields = (
        "completed_by",
        "article",
    )


class SectionOrderingAdmin(admin.ModelAdmin):
    list_display = ("pk", "_section", "_issue", "_journal", "order")
    list_display_links = ("_section",)
    list_filter = ("issue__journal",)
    search_fields = (
        "section__name",
        "issue__issue_title",
        "issue__journal__code",
        "issue__volume",
        "issue__issue",
    )

    def _journal(self, obj):
        return obj.issue.journal if obj else ""

    def _section(self, obj):
        return truncatewords(obj.section.__str__(), 10)

    def _issue(self, obj):
        return truncatewords(obj.issue.__str__(), 10)


admin_list = [
    (models.Issue, IssueAdmin),
    (models.IssueType, IssueTypeAdmin),
    (models.IssueGalley, IssueGalleyAdmin),
    (models.IssueEditor, IssueEditorAdmin),
    (models.Journal, JournalAdmin),
    (models.PinnedArticle, PinnedArticleAdmin),
    (models.PresetPublicationCheckItem, PresetPublicationCheckItemAdmin),
    (models.PrePublicationChecklistItem, PrePublicationChecklistItemAdmin),
    (models.FixedPubCheckItems, FixedPubCheckItemsAdmin),
    (models.ArticleOrdering, ArticleOrderingAdmin),
    (models.SectionOrdering, SectionOrderingAdmin),
    (models.BannedIPs, BannedIPAdmin),
    (models.Notifications, NotificationsAdmin),
]

[admin.site.register(*t) for t in admin_list]
