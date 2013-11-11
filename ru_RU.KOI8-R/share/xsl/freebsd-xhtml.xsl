<?xml version='1.0' encoding='koi8-r'?>

<!-- $FreeBSD$ -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version='1.0'
                xmlns="http://www.w3.org/TR/xhtml1/transitional"
                exclude-result-prefixes="#default">

  <xsl:template name="user.footer.navigation">
    <p align="center"><small>����, � ������ ���������, ����� ���� ������� �
    <a href="http://ftp.FreeBSD.org/pub/FreeBSD/doc/">http://ftp.FreeBSD.org/pub/FreeBSD/doc/</a>.</small></p>

    <p align="center"><small>�� ��������, ��������� � FreeBSD, ����������
    <a href="http://www.FreeBSD.org/ru/docs.html">������������</a> ������ ��� ������ �
    &lt;<a href="mailto:questions@FreeBSD.org">questions@FreeBSD.org</a>&gt;.<br/>
    �� ��������, ��������� � ���� �������������, ������ � ��������
    &lt;<a href="mailto:doc@FreeBSD.org">doc@FreeBSD.org</a>&gt;.<br/>
    </small></p>
  </xsl:template>

  <xsl:template name="docformatnav">
    <xsl:variable name="single.fname">
      <xsl:choose>
        <xsl:when test="/book">book.html</xsl:when>
        <xsl:when test="/article">article.html</xsl:when>
      </xsl:choose>
    </xsl:variable>

    <div class="docformatnavi">
      [ <a href="index.html">�� ��������</a> /
      <a href="{$single.fname}">����� ������</a> ]
    </div>
  </xsl:template>
</xsl:stylesheet>
