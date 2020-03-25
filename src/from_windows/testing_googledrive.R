library("googledrive")
drive_about()
drive_user()
drive_find(n_max = 1) %>% drive_browse()
drive_browse("https://drive.google.com/drive/folders/1D2fEQvo952krhb9jjvKl9ifwvf-plTqT")
k <- drive_find("SERC*", team_drive = "NSF RIPS WEIS")
k
as_team_drive("NSF RIPS WEIS")
td <- team_drive_find()
td$name
team_drive_get(td$name)
drive_download("https://drive.google.com/open?id=116Ib23RnrHuUk-mPGuLBlsdgkyl2Lvqn")
getwd()

serc <- team_drive_get("NSF RIPS WEIS")
a <- drive_get(as_id(serc$id))
a$drive_resource
tda1 <- team_drive_find()
as_id("https://drive.google.com/drive/folders/1bJk7C1KnusKCbzlcWZWXPP_KwzFf9-ww")
