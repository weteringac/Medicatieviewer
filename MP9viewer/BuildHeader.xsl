<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" 
    xmlns:hl7="urn:hl7-org:v3"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:nf="http://www.nictiz.nl/functions"
    xmlns:util="urn:hl7:utilities"
    xmlns="http://www.w3.org/1999/xhtml" 
    exclude-result-prefixes="xd hl7 xsi xhtml"
    xpath-default-namespace="urn:hl7-org:v3" 
    version="2.0">
    
  
    <xd:doc scope="stylesheet">
        <xd:desc>This NICTIZ stylesheet is part of MedViewer9, and takes care of generating  
            the header part of the viewer with basic patient information. If the document type is medication overview, 
            information is also displayed on the care organization that created the overview. 
            All templates expect as current node: [hl7:ClinicalDocument | hl7:organizer]
        </xd:desc>
    </xd:doc>
    
    <!-- nictizFunctions is already included in the main source file so including it here again generates a warning. -->
    <!-- You can ignore squiggly lines in oXygen that it cannot find the nf: (and util:) functions. -->
    <!--<xsl:include href="nictizFunctions.xsl"/>-->
    
    <xd:doc>
        <xd:desc>
            Creates a HTML table with general patient information from the XML source.
        </xd:desc>
        
        <xd:param name="isMO">
            Boolean that is true if the document type in Medication Overview. 
            In that case information on the care provider is shown too.
            Expected current node: [hl7:ClinicalDocument | hl7:organizer]
        </xd:param>
    </xd:doc>
    <xsl:template name="buildHeader">
        <xsl:param name="isMO" as="xs:boolean"/>
        
        <xsl:variable name="authorIsPatient" as="xs:boolean" select="author/assignedAuthor/code/@code = 'ONESELF'"/>
        
        <table>
            <!-- For MO the table has 4 columns and should be the full width. For MedData display only the left 2 columns -->
            <xsl:attribute name="style">
                <xsl:if test="$isMO">width:100%</xsl:if>
                <xsl:if test="not($isMO)">width:60%</xsl:if>
            </xsl:attribute>
            <tr>
                <td class="labelLeft">
                    <xsl:value-of select="nf:getLocalizedString('name')"/>            
                </td>
                <td class="contentLeft"><xsl:call-template name="getPatientNameBirthGender"/></td>
                <xsl:if test="$isMO and not($authorIsPatient)">
                    <td class="labelRight"><i><xsl:value-of select="nf:getLocalizedString('healthcareProvider')"/></i></td>
                    <td class="contentRight"><xsl:call-template name="getCareOrganizationName"/></td>
                </xsl:if>
                <xsl:if test="$authorIsPatient">
                    <td class="labelRight">Overzicht opgesteld door patient</td>
                </xsl:if>
            </tr>
            <tr>
                <td class="labelLeft"><xsl:value-of select="nf:getLocalizedString('addr')"/></td>
                <td class="contentLeft"><xsl:call-template name="getPatientAddress"/></td>
                
                <xsl:if test="$isMO and not($authorIsPatient)">
                    <td class="labelRight"><xsl:value-of select="nf:getLocalizedString('addr')"/></td>
                    <td class="contentRight"><xsl:call-template name="getCareOrganizationAddress"/></td>
                </xsl:if>
            </tr>
            <tr>
                <td class="labelLeft"><xsl:value-of select="nf:getLocalizedString('phone')"/></td>
                <td class="contentLeft"><xsl:call-template name="getPatientPhone"/></td>

                <xsl:if test="$isMO and not($authorIsPatient)">
                    <td class="labelRight"><xsl:value-of select="nf:getLocalizedString('phone')"/></td>
                    <td class="contentRight"><xsl:call-template name="getCareOrganizationPhone"/></td>
                </xsl:if>
            </tr>
            <tr>
                <td class="labelLeft"><xsl:value-of select="nf:getLocalizedString('bsn')"/></td>
                <td class="contentLeft"><xsl:call-template name="getPatientBSN"/></td>
                
                <xsl:if test="$isMO and not($authorIsPatient)">
                    <td class="labelRight"><xsl:value-of select="nf:getLocalizedString('email')"/></td> 
                    <td class="contentRight"><xsl:call-template name="getCareOrganizationEmail"/></td>
                </xsl:if>
            </tr>
        </table>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            Display the full patient name, together with his/her birthdate and gender (if available). 
        </xd:desc>
    </xd:doc>
    <xsl:template name="getPatientNameBirthGender">
        <b>
            <!--<xsl:value-of select="recordTarget/patientRole/patient/name"/>-->
            <xsl:call-template name="util:show-name">
                <xsl:with-param name="in" select="recordTarget/patientRole/patient/name"/>
            </xsl:call-template>
            (
            <xsl:variable name="_birthTime" select="recordTarget/patientRole/patient/birthTime/@value"/>
            <xsl:value-of select="if (string-length($_birthTime) > 0) then 
                concat(nf:printHl7DateTime($_birthTime, true()), ', ') else 
                ''"/>
            <xsl:value-of select="recordTarget/patientRole/patient/administrativeGenderCode/@code"/>
            )
        </b>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            Display the full patient address on a single line. 
        </xd:desc>
    </xd:doc>
    <xsl:template name="getPatientAddress">
        <!-- Disadvantage of displaying 'addr' as a whole, is that in Art-Decor no whitespace is added between elements -->
        <!--<xsl:value-of select="recordTarget/patientRole/addr"/>-->
        <xsl:call-template name="util:show-address">
            <xsl:with-param name="in" select="recordTarget/patientRole/addr"/>
            <xsl:with-param name="withLineBreaks" select="false()"/>
        </xsl:call-template>
        
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            Display all registered patient telephone numbers. 
        </xd:desc>
    </xd:doc>
    <xsl:template name="getPatientPhone">
        <!-- display all telecom elements that start with "tel:" -->
        <xsl:for-each select="recordTarget/patientRole/telecom">
            <xsl:value-of select="if (starts-with(@value, 'tel:')) then substring(@value,5) else ''"/>
            <xsl:text> </xsl:text>
        </xsl:for-each>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            Display the patient's national registration number (BSN). 
        </xd:desc>
    </xd:doc>
    <xsl:template name="getPatientBSN">
        <b>
            <xsl:value-of select="recordTarget/patientRole/id[@root='2.16.840.1.113883.2.4.6.3']/@extension"/>
        </b>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            Display the full name of the care organization supplying the overview. 
        </xd:desc>
    </xd:doc>
    <xsl:template name="getCareOrganizationName">
        <xsl:value-of select="author/assignedAuthor/representedOrganization/name"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            Display the full address of the care organization supplying the overview (on a single line). 
        </xd:desc>
    </xd:doc>
    <xsl:template name="getCareOrganizationAddress">
        <xsl:call-template name="util:show-address">
            <xsl:with-param name="in" select="author/assignedAuthor/representedOrganization/addr"/>
            <xsl:with-param name="withLineBreaks" select="false()"/>
        </xsl:call-template>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            Display all registered phone numbers of the care organization supplying the overview. 
        </xd:desc>
    </xd:doc>
    <xsl:template name="getCareOrganizationPhone">
        <!-- display all telecom elements that start with "tel:" -->
        <xsl:for-each select="author/assignedAuthor/representedOrganization/telecom">
            <xsl:value-of select="if (starts-with(@value, 'tel:')) then substring(@value,5) else ''"/>
            <xsl:text> </xsl:text>
        </xsl:for-each>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            Display all registered email addresses of the care organization supplying the overview. 
        </xd:desc>
    </xd:doc>
    <xsl:template name="getCareOrganizationEmail">
        <!-- display all telecom elements that start with "tel:" -->
        <xsl:for-each select="author/assignedAuthor/representedOrganization/telecom">
            <xsl:value-of select="if (starts-with(@value, 'mailto:')) then substring(@value,8) else ''"/> 
            <xsl:text> </xsl:text>
        </xsl:for-each>
    </xsl:template>
    
    
</xsl:stylesheet>