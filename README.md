# sg_vpp - Community Service Script

SG VPP is a comprehensive and modern community service script for FiveM servers, designed to be highly configurable and easy to integrate. It leverages modern libraries like `ox_lib` for its user interface and `oxmysql` for robust database persistence.

This script allows administrators and authorized personnel (like police) to sentence players to community service, where they must complete a set number of tasks in a designated area.

## Features

- **Framework Compatibility:** Supports ESX, QB-Core, and QBX out of the box.
- **Modern UI:** Utilizes `ox_lib` for a clean and intuitive admin interface, including context menus, dialogs, and progress bars.
- **Database Integration:** Persists all community service assignments using `oxmysql`. Players who disconnect will have their progress saved and restored upon reconnection.
- **Advanced Admin Panel:**
    - Assign community service with a specific task count and reason.
    - View a detailed list of all online players currently serving, including their remaining tasks and time served.
    - Cancel service for any player directly from the menu.
    - Search for players in the list by name or ID.
- **Configurable Tasks:** Easily define multiple task locations and types (e.g., cleaning), complete with custom animations, props, and durations.
- **Player Restrictions:** Automatically apply configurable restrictions to players, such as disabling weapons, phone, inventory, and confining them to a specific area with automatic teleport-back.
- **In-Game Role Access:** Allow specific jobs (e.g., `police`, `sheriff`) to access the admin menu via a configurable NPC, using either `ox_target` or simple 3D text prompts.
- **Server Announcements:** Optionally announce to the entire server when a player is sentenced to community service.
- **Detailed Logging:** Logs all administrative actions (assignments, cancellations, completions) to a dedicated `community_service_logs` database table.
- **Localization:** Comes with pre-configured language support for Czech (`cs`) and English (`en`).
- **Version Checker:** Automatically checks for new versions on startup to ensure you're always up-to-date.

## Dependencies

- **`ox_lib`**: Required for UI, notifications, and other core functions.
- **`oxmysql`**: Required for all database functionality.
- A supported framework: **`es_extended`**, **`qb-core`**, or **`qbx-core`**.

## Installation

1.  Clone or download this repository.
2.  Place the `sg_vpp` folder into your server's `resources` directory.
3.  Install all the required [dependencies](#dependencies).
4.  Thoroughly configure the `shared/config.lua` file to match your server's setup (framework, jobs, permissions, etc.).
5.  The script will automatically create the necessary database tables (`community_service` and `community_service_logs`) on the first run.
6.  Add `ensure sg_vpp` to your `server.cfg`.
7.  Restart your server.

## Configuration

The script is highly configurable via the `shared/config.lua` file. Key options include:

-   **`Config.Framework`**: Set to your server's framework (`ESX`, `QB`, or `QBX`).
-   **`Config.Database`**: Enable or disable database persistence.
-   **`Config.Admin`**: Define the ACE permission (`command.communityservice` by default) and groups (`admin`, `moderator`) that can access the admin features.
-   **`Config.Jobs`**: Configure the NPC that allows specific jobs (e.g., police) to manage community service. Set allowed jobs, NPC model, coordinates, and interaction method (`ox_target` or 3D text).
-   **`Config.Locations` & `Config.Tasks`**: Define the coordinates for service locations and the properties of each task (animation, duration, props).
-   **`Config.Restrictions`**: Toggle various restrictions for players undergoing service, including the restricted area boundaries.
-   **`Config.Teleport`**: Set spawn and release locations for players.
-   **`Config.Locales`**: Set the active language for all in-game text.

## Usage

### For Admins & Authorized Jobs

-   **`/vpp`**: Opens the main admin management menu to assign, view, or cancel community service.
-   **(NPC Interaction)**: If configured in `Config.Jobs`, members of an authorized job can interact with the designated NPC to open the admin menu.
-   **`/vppstatus`**: Shows a quick console overview of active service counts in memory and the database.
-   **`/vppsave`**: Manually saves all currently active community service sessions to the database.
-   **`/vpprestore`**: Manually triggers the process to restore service for all online players from the database.
-   **`/csstatus [player_id]`**: Checks the status of a specific player (or yourself if no ID is provided).

### For Players

-   When assigned community service, players are automatically teleported to the service area and their restrictions are applied.
-   Task locations are marked on their map.
-   Players must go to a marker and press `E` to perform a task, which will trigger an animation and a progress bar.
-   Upon completing a task, their remaining task count is updated.
-   Once all tasks are finished, they are freed, teleported to a release location, and all restrictions are lifted.

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.
