import random
from uuid import uuid4
from faker import Faker

from django.core.management.base import BaseCommand
from django.utils import timezone

from journal import models as journal_models
from submission import models as sm_models
from core import models as core_models
from utils.testing.helpers import create_article, create_frozen_author, create_galley


class Command(BaseCommand):
    """A management command to generate random dummy articles for a journal."""

    help = "Generate random dummy articles for a journal. Usage: manage.py generate_dummy_articles <journal_code> [number]"

    def add_arguments(self, parser):
        parser.add_argument("journal_code", help="The journal code to add articles to")
        parser.add_argument(
            "number",
            nargs="?",
            default=5,
            type=int,
            help="Number of dummy articles to create (default: 5)",
        )
        parser.add_argument(
            "--published",
            action="store_true",
            help="Make articles published (default: draft)",
        )
        parser.add_argument(
            "--with-authors",
            action="store_true",
            help="Create frozen authors for articles",
        )
        parser.add_argument(
            "--with-galleys",
            action="store_true",
            help="Create galley files for articles",
        )

    def handle(self, *args, **options):
        journal_code = options.get("journal_code")
        number = options.get("number", 5)
        published = options.get("published", False)
        with_authors = options.get("with_authors", False)
        with_galleys = options.get("with_galleys", False)

        fake = Faker()

        try:
            journal = journal_models.Journal.objects.get(code=journal_code)
        except journal_models.Journal.DoesNotExist:
            self.stdout.write(
                self.style.ERROR(f"Journal with code {journal_code} not found.")
            )
            return

        # Get or create an author account
        try:
            author_account = core_models.Account.objects.filter(
                accountrole__journal=journal,
                accountrole__role__slug="author",
            ).first()
            if not author_account:
                author_account = core_models.Account.objects.create_user(
                    email="dummy_author@example.com"
                )
                author_account.is_active = True
                author_account.save()
        except Exception as e:
            author_account = core_models.Account.objects.first()

        self.stdout.write(f"Creating {number} dummy articles for journal: {journal.name}")

        for i in range(number):
            try:
                # Create the article
                section = sm_models.Section.objects.filter(journal=journal).first()
                if not section:
                    section = self._create_section(journal)
                
                article = sm_models.Article.objects.create(
                    journal=journal,
                    title=fake.sentence(nb_words=8),
                    abstract=fake.paragraph(nb_sentences=5),
                    article_agreement="Dummy Article",
                    section=section,
                    stage=sm_models.STAGE_PUBLISHED if published else sm_models.STAGE_UNASSIGNED,
                )

                if published:
                    article.date_published = timezone.now()
                    article.save()

                # Add frozen authors
                if with_authors:
                    num_authors = random.randint(1, 4)
                    for _ in range(num_authors):
                        create_frozen_author(article)

                # Add a galley/file
                if with_galleys:
                    create_galley(article)

                self.stdout.write(
                    self.style.SUCCESS(f"✓ Created article: {article.title[:50]}...")
                )

            except Exception as e:
                self.stdout.write(
                    self.style.ERROR(f"✗ Error creating article {i+1}: {str(e)}")
                )

        self.stdout.write(
            self.style.SUCCESS(f"\nSuccessfully created {number} dummy articles!")
        )

    def _create_section(self, journal):
        """Create a default section if none exists"""
        section, created = sm_models.Section.objects.get_or_create(
            journal=journal,
            defaults={
                "name": "Article",
                "plural": "Articles",
                "number_of_reviewers": 2,
            },
        )
        return section
