document.addEventListener("DOMContentLoaded", function () {
    const userMenu = document.querySelector(".user-menu");
    const userDropup = document.querySelector(".user-dropup");
    const arrowIcon = document.querySelector(".user-menu .arrow");

    function showMenu() {
        userDropup.style.visibility = "visible";
        userDropup.style.opacity = "1";
        arrowIcon.style.transform = "rotate(180deg)";
    }

    function hideMenu() {
        setTimeout(() => {
            if (!userMenu.matches(":hover") && !userDropup.matches(":hover")) {
                userDropup.style.visibility = "hidden";
                userDropup.style.opacity = "0";
                arrowIcon.style.transform = "rotate(0deg)";
            }
        }, 200);
    }

    userMenu.addEventListener("mouseenter", showMenu);
    userDropup.addEventListener("mouseenter", showMenu);

    userMenu.addEventListener("mouseleave", hideMenu);
    userDropup.addEventListener("mouseleave", hideMenu);
});

