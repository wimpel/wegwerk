library(data.table)
library(xml2)
library(magrittr)
library(fasttime)

# Bestend om in te lezen
xmlFile <- "./data/wegwerkzaamheden.xml"
# xml doc inlezen
doc <- xml2::read_xml(xmlFile)
# heeft de xml nog namespaces om rekening mee te houden?
xml2::xml_ns(doc)
# Ja dus...
### d1   <-> http://datex2.eu/schema/2/2_0                <-- hier staan de relevante nodes in
### SOAP <-> http://schemas.xmlsoap.org/soap/envelope/
### xsi  <-> http://www.w3.org/2001/XMLSchema-instance
### xsi1 <-> http://www.w3.org/2001/XMLSchema-instance

# haal situation nodes op
situation.nodes <- xml2::xml_find_all(doc, "//d1:situation")
# haal alle situationRedord-nodes op
situationRecord.nodes <- xml2::xml_find_all(doc, "//d1:situation/d1:situationRecord")

# haal data uit situation nodes
DT.situation <- data.table::data.table(
  id      = xml2::xml_attr(situation.nodes, "id"),
  version = xml2::xml_attr(situation.nodes, "version"),
  overallSeverity = xml2::xml_find_first(situation.nodes, "./d1:overallSeverity") %>% 
    xml2::xml_text(),
  situationVersionTime = xml2::xml_find_first(situation.nodes, "./d1:situationVersionTime") %>% 
    xml2::xml_text() %>%
    fasttime::fastPOSIXct(tz = "UTC"), # inlezen als POSIX tijdstempel, UTC tijdzone !!
  confidentiality = xml2::xml_find_first(situation.nodes, "./d1:headerInformation/d1:confidentiality") %>% 
    xml2::xml_text(),
  informationStatus = xml2::xml_find_first(situation.nodes, "./d1:headerInformation/d1:informationStatus") %>% 
    xml2::xml_text()
)

# haal data uit de situationRecord nodes
DT.situationRecord <- data.table::data.table(
  parent_id = sapply( situationRecord.nodes, 
                      function(x) xml2::xml_parent(x) %>% xml2::xml_attr("id")),
  id      = xml2::xml_attr(situationRecord.nodes, "id"),
  version = xml2::xml_attr(situationRecord.nodes, "version"),
  type    = xml2::xml_attr(situationRecord.nodes, "type"),
  situationRecordCreationTime = xml2::xml_find_first(situationRecord.nodes, "./d1:situationRecordCreationTime") %>%
    xml2::xml_text() %>%
    fasttime::fastPOSIXct(tz = "UTC"), # inlezen als POSIX tijdstempel, UTC tijdzone !!
  situationRecordVersionTime = xml2::xml_find_first(situationRecord.nodes, "./d1:situationRecordVersionTime") %>%
    xml2::xml_text() %>%
    fasttime::fastPOSIXct(tz = "UTC"), # inlezen als POSIX tijdstempel, UTC tijdzone !!
  sourceName = xml2::xml_find_first(situationRecord.nodes, ".//d1:source/d1:sourceName/d1:values/d1:value") %>%
    xml2::xml_text(),
  overallStartTime = xml2::xml_find_first(situationRecord.nodes, "./d1:validity/d1:validityTimeSpecification/d1:overallStartTime") %>%
    xml2::xml_text() %>%
    fasttime::fastPOSIXct(tz = "UTC"), # inlezen als POSIX tijdstempel, UTC tijdzone !!
  overallEndTime = xml2::xml_find_first(situationRecord.nodes, "././d1:validity/d1:validityTimeSpecification/d1:overallEndTime") %>%
    xml2::xml_text() %>%
    fasttime::fastPOSIXct(tz = "UTC") # inlezen als POSIX tijdstempel, UTC tijdzone !!
)

# wegschijven aangemaakte datasets
write.csv(DT.situation, "./output/situations.csv")
write.csv(DT.situationRecord, "./output/situationRecords.csv")
