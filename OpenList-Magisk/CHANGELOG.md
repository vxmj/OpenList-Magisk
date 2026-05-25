### &nbsp;&nbsp;&nbsp;🚨 Breaking Changes

- **cache**: Extract hybrid_cache package &nbsp;-&nbsp; by @j2rong4cn in https://github.com/OpenListTeam/OpenList/issues/2477 [<samp>(9eae6)</samp>](https://github.com/OpenListTeam/OpenList/commit/9eae6258)
- **settings**: Move FilterReadMeScripts to frontend &nbsp;-&nbsp; by @xrgzs in https://github.com/OpenListTeam/OpenList/issues/2346 [<samp>(a5ba6)</samp>](https://github.com/OpenListTeam/OpenList/commit/a5ba6a0e)

### &nbsp;&nbsp;&nbsp;🚀 Features

- **115_open**: Implement Getter interface &nbsp;-&nbsp; by @sevxn007 in https://github.com/OpenListTeam/OpenList/issues/1811 [<samp>(07506)</samp>](https://github.com/OpenListTeam/OpenList/commit/07506b00)
- **189pc**: Implement AccessToken login &nbsp;-&nbsp; by @zypluckyphoenix in https://github.com/OpenListTeam/OpenList/issues/2245 [<samp>(0726d)</samp>](https://github.com/OpenListTeam/OpenList/commit/0726d166)
- **func**: Support ed2k & magnet & torrent offline download &nbsp;-&nbsp; by @PIKACHUIM in https://github.com/OpenListTeam/OpenList/issues/2452 [<samp>(1d071)</samp>](https://github.com/OpenListTeam/OpenList/commit/1d071c0f)
- **s3**: Implement Getter interface &nbsp;-&nbsp; by @ZRHann in https://github.com/OpenListTeam/OpenList/issues/1790 [<samp>(9033b)</samp>](https://github.com/OpenListTeam/OpenList/commit/9033b550)
- **sharing**: Allow custom share IDs &nbsp;-&nbsp; by @MuelNova in https://github.com/OpenListTeam/OpenList/issues/2353 [<samp>(7e37c)</samp>](https://github.com/OpenListTeam/OpenList/commit/7e37c405)
- **webdav**: Implement Getter interface &nbsp;-&nbsp; by @ZRHann and **Copilot** in https://github.com/OpenListTeam/OpenList/issues/2421 [<samp>(e2840)</samp>](https://github.com/OpenListTeam/OpenList/commit/e28406fa)

### &nbsp;&nbsp;&nbsp;🐞 Bug Fixes

- **115**:
  - Fix capacity display and CDN 403 errors &nbsp;-&nbsp; by @SheltonZhu in https://github.com/OpenListTeam/OpenList/issues/2510 [<samp>(ffbbc)</samp>](https://github.com/OpenListTeam/OpenList/commit/ffbbc1cc)
- **189pc**:
  - Handle numeric res_code in RenameResp to fix JSON unmarshal error &nbsp;-&nbsp; by @PIKACHUIM in https://github.com/OpenListTeam/OpenList/issues/2489 [<samp>(b2820)</samp>](https://github.com/OpenListTeam/OpenList/commit/b28208bd)
- **about**:
  - Fix large logo on about page &nbsp;-&nbsp; by @jyxjjj in https://github.com/OpenListTeam/OpenList/issues/2418 [<samp>(201a2)</samp>](https://github.com/OpenListTeam/OpenList/commit/201a206e)
- **driver**:
  - Fix 189 & 189pc fastcopy form local storage &nbsp;-&nbsp; by @PIKACHUIM in https://github.com/OpenListTeam/OpenList/issues/2471 [<samp>(7feec)</samp>](https://github.com/OpenListTeam/OpenList/commit/7feec2b7)
- **driver/139**:
  - Remove RFC-incompatible request header &nbsp;-&nbsp; by @Copilot and **jyxjjj** in https://github.com/OpenListTeam/OpenList/issues/2478 [<samp>(daad2)</samp>](https://github.com/OpenListTeam/OpenList/commit/daad21ef)
- **drivers**:
  - Add headers in Link methods &nbsp;-&nbsp; by @xrgzs in https://github.com/OpenListTeam/OpenList/issues/2401 [<samp>(ece15)</samp>](https://github.com/OpenListTeam/OpenList/commit/ece1518e)
- **drivers/139**:
  - Check cdnSwitch before returning cdnUrl in personalGetLink &nbsp;-&nbsp; by @xrgzs in https://github.com/OpenListTeam/OpenList/issues/2379 [<samp>(331f5)</samp>](https://github.com/OpenListTeam/OpenList/commit/331f575c)
- **drivers/local**:
  - Capture ENOTTY in reflink to allow fallback &nbsp;-&nbsp; by @elysia-best in https://github.com/OpenListTeam/OpenList/issues/2492 [<samp>(7cfb2)</samp>](https://github.com/OpenListTeam/OpenList/commit/7cfb2555)
- **drivers/wps**:
  - Implement driver.GetRooter interface &nbsp;-&nbsp; by @xrgzs in https://github.com/OpenListTeam/OpenList/issues/2414 [<samp>(37663)</samp>](https://github.com/OpenListTeam/OpenList/commit/37663897)
  - Correct account relevant handling &nbsp;-&nbsp; by @xrgzs and **Copilot** in https://github.com/OpenListTeam/OpenList/issues/2415 [<samp>(2d2d9)</samp>](https://github.com/OpenListTeam/OpenList/commit/2d2d9ae2)
- **fsmanage**:
  - Improve path validation &nbsp;-&nbsp; by @j2rong4cn in https://github.com/OpenListTeam/OpenList/issues/2437 [<samp>(c7c0c)</samp>](https://github.com/OpenListTeam/OpenList/commit/c7c0cfae)
- **internal/fs**:
  - Add ObjectAlreadyExists error check &nbsp;-&nbsp; by @mkitsdts in https://github.com/OpenListTeam/OpenList/issues/2019 [<samp>(e87e0)</samp>](https://github.com/OpenListTeam/OpenList/commit/e87e028a)
- **offline_download**:
  - Fix login failure caused by qBittorrent 5.2.0 returning HTTP 204 No Content on successful authentication &nbsp;-&nbsp; by @yuanczx in https://github.com/OpenListTeam/OpenList/issues/2476 [<samp>(31b41)</samp>](https://github.com/OpenListTeam/OpenList/commit/31b41f99)
- **qbittorrent**:
  - Handle non-200 response during login to prevent long startup waits &nbsp;-&nbsp; by @airium in https://github.com/OpenListTeam/OpenList/issues/2248 [<samp>(bfda7)</samp>](https://github.com/OpenListTeam/OpenList/commit/bfda719e)
- **setting**:
  - Handle delete of setting item with empty key &nbsp;-&nbsp; by @j2rong4cn in https://github.com/OpenListTeam/OpenList/issues/2131 [<samp>(ea19b)</samp>](https://github.com/OpenListTeam/OpenList/commit/ea19bed2)

### &nbsp;&nbsp;&nbsp;🏎 Performance

- Replace strings.Split with strings.SplitSeq &nbsp;-&nbsp; by @j2rong4cn in https://github.com/OpenListTeam/OpenList/issues/2441 [<samp>(d3a6b)</samp>](https://github.com/OpenListTeam/OpenList/commit/d3a6b065)

##### &nbsp;&nbsp;&nbsp;&nbsp;[View changes on GitHub](https://github.com/OpenListTeam/OpenList/compare/v4.2.1...v4.2.2)
