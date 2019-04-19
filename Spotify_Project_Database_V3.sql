drop database if exists spootify;
create database spootify;
use spootify;



        
create table genre (
	genre_id int primary key,
    genre_name varchar(30)
    );
 

insert into genre values
	(1, 'country'),
    (2, 'alternative'),
    (3, 'hip-hop'),
    (4, 'pop');
    
 create table artist (
	artist_id varchar(10) primary key,
    artist_name varchar(75) not null,
    genre_id int not null,
    constraint fk_genre_id_artist foreign key(genre_id) references genre(genre_id)
    );

insert into artist values
	('1', 'Lil Nas X', 1),
    ('2', 'Billie Eilish', 2),
    ('3', 'J. Cole', 3),
    ('4', 'Post Malone', 3),
    ('5', 'Ariana Grande', 4);
    
    
create table album (
	album_id varchar(10) primary key,
    album_name varchar(75)
    );
    

insert into album values
	('1', 'Old Town Road'),
    ('2', 'When We All Fall'),
    ('3', 'Middle Child - Single'),
    ('4', 'Sunflower - Spider-Man: Into the Spider-Verse'),
    ('5', 'thank u, next');
    ;
    
create table song(
	spotify_id varchar(10) primary key,
    title varchar(75) not null,
    artist_id varchar(10) not null,
    album_id varchar(10) not null,
    song_value int not null,
    constraint fk_artist_id_song foreign key(artist_id) references artist(artist_id),
    constraint fk_album_id_song foreign key(album_id) references album(album_id)
    );
    
insert into song values
	('1', 'Old Town Road - Remix', 1, 1, 293),
    ('2', 'bad guy', 2, 2, 193),
    ('3', 'wish you were gay', 2, 2, 112),
    ('4', 'ilomilo', 2, 2, 40),
    ('5', 'Middle Child', 3, 3, 112);
    
    
    
create table song_history (
	date date not null,
    spotify_id varchar(10) not null,
    day_value int not null,
    constraint fk_spotify_id_song_history foreign key(spotify_id) references song(spotify_id)
    );
    
insert into song_history values 
    ('2019-04-08', '1', 311),
    ('2019-04-08', '2', 202),
    ('2019-04-08', '3', 118),
    ('2019-04-08', '4', 53),
    ('2019-04-08', '5', 108),
    ('2019-04-09', '1', 310),
    ('2019-04-09', '2', 197),
    ('2019-04-09', '3', 115),
    ('2019-04-09', '4', 51),
    ('2019-04-09', '5', 111),
    ('2019-04-10', '1', 293),
    ('2019-04-10', '2', 187),
    ('2019-04-10', '3', 116),
    ('2019-04-10', '4', 49),
    ('2019-04-10', '5', 121),
    ('2019-04-11', '1', 271),
    ('2019-04-11', '2', 182),
    ('2019-04-11', '3', 108),
    ('2019-04-11', '4', 47),
    ('2019-04-11', '5', 110),
    ('2019-04-12', '1', 281),
    ('2019-04-12', '2', 189),
    ('2019-04-12', '3', 110),
    ('2019-04-12', '4', 97),
    ('2019-04-12', '5', 118);
    
    
    

create table user (
	user_id int primary key auto_increment,
    full_name varchar(50) not null,
    user_name varchar(25) unique not null,
    email varchar(255) unique not null,
    password varchar(30) not null,
    created datetime not null,
    purchasing_power int not null
    );

insert into user values
	(1, 'm', 'm', 'm@m.com', 'password', '2019-04-08 03:02:54', 5000),
    (2, 'n', 'n', 'n@n.com', 'password', '2019-04-08 03:02:54', 5000);

create table user_history (
	date date not null,
    user_id int not null,
    portfolio_value int not null,
    constraint fk_spotify_id_user_history foreign key(user_id) references user(user_id)
    );
    
create table buy (
	buy_id int primary key auto_increment,
	user_id int not null,
    spotify_id varchar(10) not null,
    price int not null,
    n_shares int not null,
    purchase_time datetime not null,
    constraint fk_user_id_buy foreign key(user_id) references user(user_id),
    constraint fk_spotify_id_buy foreign key(spotify_id) references song(spotify_id)
    );
    
    
    
create table sell (
	sell_id int primary key auto_increment,
	user_id int not null,
    spotify_id varchar(10) not null,
    price int not null,
    n_shares int not null,
    sale_time datetime not null,
    constraint fk_user_id_sell foreign key(user_id) references user(user_id),
    constraint fk_spotfiy_id_sell foreign key(spotify_id) references song(spotify_id)
    );
    


            
-- buying trigger
Drop Trigger If Exists buy_triggers;

Delimiter //
Create Trigger buy_triggers
	Before Insert On buy
    For Each Row
Begin
	If ((New.price * New.n_shares) > (Select purchasing_power as u_power
										From user
										Where New.user_id = user.user_id))
		Then
		Signal Sqlstate 'HYOOO'
			Set Message_Text = 'Insufficient Funds';
	End If;
    If (time(New.purchase_time) < '09:30' Or time(New.purchase_time) > '16:30') Then
		Signal Sqlstate 'HYOOO'
			Set Message_Text = 'Market Closed';
	Else
		Update user
        Set purchasing_power = purchasing_power - (New.n_shares * New.price)
        Where user.user_id = New.user_id;
	End If;
End //


Delimiter //

-- function that calculates shares of given stock bought by a given user
CREATE FUNCTION shares_bought (u_id INT, s_id varchar(10))
RETURNS INT

BEGIN
DECLARE bought INT;

Select sum(n_shares) into bought
From buy
Where u_id = user_id And s_id = spotify_id
Group by user_id, spotify_id;

RETURN bought;
END //

Delimiter //

-- function that calculates shares of given stock sold by a given user
CREATE FUNCTION shares_sold (u_id INT, s_id varchar(10))
RETURNS INT

BEGIN
DECLARE sold INT;

Select sum(n_shares) into sold
From sell
Where u_id = user_id And s_id = spotify_id
Group by user_id, spotify_id;

RETURN sold;
END //


Drop Trigger If Exists sell_triggers;

Delimiter //


-- trigger based of sales being made
Create Trigger sell_triggers
	Before Insert On sell
    For Each Row
Begin
	If (New.n_shares > shares_bought(New.user_id, New.spotify_id) - shares_sold(New.user_id, New.spotify_id)) Then
		Signal Sqlstate 'HYOOO'
			Set Message_Text = 'Not Enough Shares';
	End If;
    If (time(New.sale_time) < '09:30' Or time(New.sale_time) > '16:30') Then
		Signal Sqlstate 'HYOOO'
			Set Message_Text = 'Market Closed';
	Else
		Update user
        Set purchasing_power = purchasing_power + (New.n_shares * New.price)
        Where user.user_id = New.user_id;
	End If;
End //
 

-- updates song history every day
create event update_song_history
	on schedule every 1 day
	starts '2019-01-01 00:05:00' 
do
	insert into song_history
    select curdate(), spotify_id, song_value
    from song;

-- updates user history every day
create event update_user_history
	on schedule every 1 day
	starts '2019-01-01 00:09:00'
do
	insert into user_history
    select curdate(), user_id, portfolio_value
    from 
    (Select user_id, (sum(total_value) + purchasing_power) as portfolio_value
		From
		(Select user_id, spotify_id, shares_owned * song_value as total_value
		From
			(Select user_id, spotify_id, user_bought - coalesce(user_sold,0) as shares_owned
			From 
				(Select user_id, spotify_id, sum(n_shares) as user_bought
				From buy
				Group by user_id, spotify_id) as total_bought
			Left Join 
				(Select user_id, spotify_id, sum(n_shares) as user_sold
				From sell
				Group by user_id, spotify_id) as total_sold
				Using (user_id, spotify_id)) as user_total
		Join song Using (spotify_id)) as user_share_value
	Join user Using (user_id)
	Group by user_id) as daily_portfolio
Where user.user_id = daily_portfolio.user_id;

 
Delimiter //
insert into buy values
	(1, 1, '1', 311, 5, '2019-04-08 12:02:54'),
    (2, 1, '5', 108, 6, '2019-04-08 12:02:54'),
    (3, 1, '5', 111, 5, '2019-04-09 12:02:54'),
    (4, 1, '2', 111, 5, '2019-04-09 12:02:54'),
    (5, 2, '2', 116, 3, '2019-04-10 12:02:54');

insert into sell values
	(1, 1, '1', 293, 2, '2019-04-10 14:02:54'),
    (2, 1, '5', 121, 10, '2019-04-10 14:02:54');
  
 
Select *
From song;

    

Select user_id, spotify_id, sum(n_shares) as user_bought
From buy
Group by user_id, spotify_id;

Select user_id, spotify_id, sum(n_shares) as user_sold
From sell
Group by user_id, spotify_id;  


Select spotify_id, title, artist_id, album_id, song_value, user_bought - coalesce(user_sold,0) as shares_owned
		From 
			(Select user_id, spotify_id, sum(n_shares) as user_bought
			From buy
			Group by user_id, spotify_id) as total_bought
		Left Join 
			(Select user_id, spotify_id, sum(n_shares) as user_sold
			From sell
			Group by user_id, spotify_id) as total_sold
		Using (user_id, spotify_id)
		Join song Using (spotify_id)
Where user_id = '1';
 
 
 
-- value and number of shares given user owns
Select user_id, title, shares_owned * song_value as song_total
		From
			(Select user_id, spotify_id, user_bought - coalesce(user_sold,0) as shares_owned
			From 
				(Select user_id, spotify_id, sum(n_shares) as user_bought
				From buy
				Group by user_id, spotify_id) as total_bought
			Left Join 
				(Select user_id, spotify_id, sum(n_shares) as user_sold
				From sell
				Group by user_id, spotify_id) as total_sold
				Using (user_id, spotify_id)) as user_total
		Join song Using (spotify_id);
        
-- portfolio value of given user
Select sum(song_total) + purchasing_power as portfolio_value
	From
		(Select user_id, title, shares_owned * song_value as song_total
		From
			(Select user_id, spotify_id, user_bought - coalesce(user_sold,0) as shares_owned
			From 
				(Select user_id, spotify_id, sum(n_shares) as user_bought
				From buy
				Group by user_id, spotify_id) as total_bought
			Left Join 
				(Select user_id, spotify_id, sum(n_shares) as user_sold
				From sell
				Group by user_id, spotify_id) as total_sold
				Using (user_id, spotify_id)) as user_total
		Join song Using (spotify_id)) as all_songs
	Join user Using (user_id)
Where user_id = '1';

        
-- portfolio value of user


-- last 7 days of history of given user
Select date, portfolio_value
From user_history
Where user_id = '1'
Order by date
Limit 7;

-- returns the value of the given song
Select song_value
From song
Where spotify_id = '1';


-- all # of shares given user owns
SELECT spotify_id, title, artist_id, album_id, song_value, user_bought - COALESCE(user_sold,0) AS owned
			FROM
				(SELECT user_id, spotify_id, SUM(n_shares) AS user_bought
				FROM buy
				GROUP BY user_id, spotify_id) AS total_bought
			LEFT JOIN 
				(SELECT user_id, spotify_id, SUM(n_shares) AS user_sold
				FROM sell
				GROUP BY user_id, spotify_id) AS total_sold
				USING (user_id, spotify_id)) AS user_total
		JOIN song USING (spotify_id);

        
-- history of given song value past 7 days
Select date, day_value
From song_history
Where song_id = @;

-- list of songs from given artist
Select *
From song
Join artist Using (artist_id)
Where artist_name Like @;

-- list of songs from given genre
Select *
From song
Join artist Using (artist_id)
Join genre Using (genre_id)
Where genre_name Like @;

-- list of songs from given album
Select *
From song
Join album Using (artist_id)
Where album_name Like @;
