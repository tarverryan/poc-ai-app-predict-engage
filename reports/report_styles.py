"""
Report Styling and Formatting Constants
Professional color schemes, typography, and layout constants for executive reports
"""

from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT, TA_JUSTIFY

# Page Setup
PAGE_WIDTH, PAGE_HEIGHT = letter
MARGIN = 0.75 * inch
CONTENT_WIDTH = PAGE_WIDTH - 2 * MARGIN
CONTENT_HEIGHT = PAGE_HEIGHT - 2 * MARGIN

# Color Palette (Executive-Friendly)
class Colors:
    # Primary Colors
    NAVY = colors.HexColor('#1e3a5f')
    NAVY_LIGHT = colors.HexColor('#2d5a8c')
    NAVY_DARK = colors.HexColor('#0f1d30')
    
    # Accent Colors
    GOLD = colors.HexColor('#d4af37')
    GOLD_LIGHT = colors.HexColor('#e5c663')
    
    # Status Colors
    SUCCESS = colors.HexColor('#2ecc71')
    WARNING = colors.HexColor('#f39c12')
    DANGER = colors.HexColor('#e74c3c')
    INFO = colors.HexColor('#3498db')
    
    # Neutrals
    GRAY_DARK = colors.HexColor('#2c3e50')
    GRAY = colors.HexColor('#7f8c8d')
    GRAY_LIGHT = colors.HexColor('#bdc3c7')
    GRAY_LIGHTER = colors.HexColor('#ecf0f1')
    WHITE = colors.white
    BLACK = colors.black
    
    # Chart Colors
    CHART_PRIMARY = [
        colors.HexColor('#1e3a5f'),
        colors.HexColor('#3498db'),
        colors.HexColor('#2ecc71'),
        colors.HexColor('#f39c12'),
        colors.HexColor('#e74c3c'),
        colors.HexColor('#9b59b6'),
        colors.HexColor('#1abc9c'),
        colors.HexColor('#34495e'),
    ]

# Typography
class Fonts:
    TITLE = 'Helvetica-Bold'
    HEADING = 'Helvetica-Bold'
    SUBHEADING = 'Helvetica'
    BODY = 'Helvetica'
    BODY_BOLD = 'Helvetica-Bold'
    CAPTION = 'Helvetica-Oblique'
    
    # Sizes (Further reduced for optimal fit)
    SIZE_TITLE = 20
    SIZE_H1 = 14
    SIZE_H2 = 11
    SIZE_H3 = 10
    SIZE_BODY = 8
    SIZE_CAPTION = 7

# Create Custom Styles
def get_custom_styles():
    """Return custom paragraph styles for the report"""
    styles = getSampleStyleSheet()
    
    # Cover Title
    styles.add(ParagraphStyle(
        name='CoverTitle',
        parent=styles['Title'],
        fontName=Fonts.TITLE,
        fontSize=22,
        textColor=Colors.NAVY,
        spaceAfter=12,
        alignment=TA_CENTER,
    ))
    
    # Cover Subtitle
    styles.add(ParagraphStyle(
        name='CoverSubtitle',
        parent=styles['Normal'],
        fontName=Fonts.HEADING,
        fontSize=12,
        textColor=Colors.GRAY_DARK,
        spaceAfter=15,
        alignment=TA_CENTER,
    ))
    
    # Section Title
    styles.add(ParagraphStyle(
        name='SectionTitle',
        parent=styles['Heading1'],
        fontName=Fonts.HEADING,
        fontSize=Fonts.SIZE_H1,
        textColor=Colors.NAVY,
        spaceBefore=8,
        spaceAfter=6,
        borderPadding=5,
        borderColor=Colors.NAVY,
        borderWidth=0,
        leftIndent=0,
    ))
    
    # Heading 2
    styles.add(ParagraphStyle(
        name='Heading2Custom',
        parent=styles['Heading2'],
        fontName=Fonts.HEADING,
        fontSize=Fonts.SIZE_H2,
        textColor=Colors.NAVY_LIGHT,
        spaceBefore=6,
        spaceAfter=4,
    ))
    
    # Heading 3
    styles.add(ParagraphStyle(
        name='Heading3Custom',
        parent=styles['Heading3'],
        fontName=Fonts.SUBHEADING,
        fontSize=Fonts.SIZE_H3,
        textColor=Colors.GRAY_DARK,
        spaceBefore=4,
        spaceAfter=2,
    ))
    
    # Body
    styles.add(ParagraphStyle(
        name='BodyCustom',
        parent=styles['Normal'],
        fontName=Fonts.BODY,
        fontSize=Fonts.SIZE_BODY,
        textColor=Colors.GRAY_DARK,
        spaceBefore=2,
        spaceAfter=2,
        alignment=TA_JUSTIFY,
        leading=10,
    ))
    
    # Bullet
    styles.add(ParagraphStyle(
        name='BulletCustom',
        parent=styles['Normal'],
        fontName=Fonts.BODY,
        fontSize=Fonts.SIZE_BODY,
        textColor=Colors.GRAY_DARK,
        leftIndent=12,
        bulletIndent=6,
        spaceBefore=1,
        spaceAfter=1,
    ))
    
    # Caption
    styles.add(ParagraphStyle(
        name='CaptionCustom',
        parent=styles['Normal'],
        fontName=Fonts.CAPTION,
        fontSize=Fonts.SIZE_CAPTION,
        textColor=Colors.GRAY,
        alignment=TA_CENTER,
        spaceBefore=5,
    ))
    
    # KPI Value
    styles.add(ParagraphStyle(
        name='KPIValue',
        parent=styles['Normal'],
        fontName=Fonts.TITLE,
        fontSize=14,
        textColor=Colors.NAVY,
        alignment=TA_CENTER,
    ))
    
    # KPI Label
    styles.add(ParagraphStyle(
        name='KPILabel',
        parent=styles['Normal'],
        fontName=Fonts.BODY,
        fontSize=7,
        textColor=Colors.GRAY,
        alignment=TA_CENTER,
    ))
    
    return styles

# Layout Constants
class Layout:
    TWO_COLUMN_WIDTH = CONTENT_WIDTH / 2 - 10
    THREE_COLUMN_WIDTH = CONTENT_WIDTH / 3 - 10
    CHART_WIDTH = CONTENT_WIDTH * 0.65
    CHART_HEIGHT = 3.5 * inch
    CHART_SMALL_HEIGHT = 2.5 * inch
    
    SPACER_SMALL = 0.08 * inch
    SPACER_MEDIUM = 0.15 * inch
    SPACER_LARGE = 0.25 * inch

# Chart Styling
class ChartStyles:
    DPI = 300
    FIGURE_FACECOLOR = 'white'
    AXES_FACECOLOR = '#f8f9fa'
    GRID_COLOR = '#dee2e6'
    GRID_ALPHA = 0.5
    TITLE_SIZE = 10
    LABEL_SIZE = 8
    TICK_SIZE = 6
    LEGEND_SIZE = 7

def format_currency(value):
    """Format number as currency"""
    if value >= 1_000_000:
        return f"${value/1_000_000:.1f}M"
    elif value >= 1_000:
        return f"${value/1_000:.0f}K"
    else:
        return f"${value:.0f}"

def format_percentage(value, decimals=1):
    """Format number as percentage"""
    return f"{value:.{decimals}f}%"

def format_number(value, decimals=0):
    """Format number with commas"""
    if decimals == 0:
        return f"{value:,.0f}"
    else:
        return f"{value:,.{decimals}f}"

def get_status_color(value, threshold_good, threshold_warning, higher_is_better=True):
    """Return color based on value and thresholds"""
    if higher_is_better:
        if value >= threshold_good:
            return Colors.SUCCESS
        elif value >= threshold_warning:
            return Colors.WARNING
        else:
            return Colors.DANGER
    else:
        if value <= threshold_good:
            return Colors.SUCCESS
        elif value <= threshold_warning:
            return Colors.WARNING
        else:
            return Colors.DANGER

